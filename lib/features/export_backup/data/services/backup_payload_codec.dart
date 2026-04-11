import 'dart:convert';

import '../../domain/entities/backup_restore_preview_entity.dart';
import '../../domain/entities/backup_validation_result_entity.dart';

class BackupPayloadCodec {
  const BackupPayloadCodec({
    this.currentDatabaseVersion = 9,
    this.currentBackupFormatVersion = 1,
  });

  final int currentDatabaseVersion;
  final int currentBackupFormatVersion;

  BackupValidationResultEntity parseAndValidatePayload({
    required String fileName,
    required String rawContent,
  }) {
    final decoded = jsonDecode(rawContent);

    if (decoded is! Map) {
      throw const FormatException(
        'El archivo seleccionado no tiene un formato de respaldo válido.',
      );
    }

    return validatePayload(
      fileName: fileName,
      payload: Map<String, dynamic>.from(decoded),
    );
  }

  BackupValidationResultEntity validatePayload({
    required String fileName,
    required Map<String, dynamic> payload,
  }) {
    _ensureRequiredKey(
      payload,
      'app',
      'El respaldo seleccionado no contiene metadata de aplicación.',
    );
    _ensureRequiredKey(
      payload,
      'accounts',
      'El respaldo seleccionado no contiene cuentas.',
    );
    _ensureRequiredKey(
      payload,
      'categories',
      'El respaldo seleccionado no contiene categorías.',
    );
    _ensureRequiredKey(
      payload,
      'transactions',
      'El respaldo seleccionado no contiene movimientos.',
    );
    _ensureRequiredKey(
      payload,
      'budgets',
      'El respaldo seleccionado no contiene presupuestos.',
    );
    _ensureRequiredKey(
      payload,
      'goals',
      'El respaldo seleccionado no contiene metas.',
    );
    _ensureRequiredKey(
      payload,
      'recurring_transactions',
      'El respaldo seleccionado no contiene movimientos recurrentes.',
    );

    final normalizedPayload = normalizePayload(payload);
    final app = _readMap(normalizedPayload['app']);

    final format = app['format']?.toString().trim();
    if (format != 'json-backup') {
      throw const FormatException(
        'El archivo seleccionado no corresponde a un respaldo JSON de Finaper.',
      );
    }

    final appName = app['name']?.toString().trim();
    if (appName != 'Finaper') {
      throw const FormatException(
        'El archivo seleccionado no pertenece a Finaper.',
      );
    }

    final databaseVersion = _readInt(app['database_version']) ?? 7;
    if (databaseVersion < 7 || databaseVersion > currentDatabaseVersion) {
      throw FormatException(
        'La versión del respaldo ($databaseVersion) no es compatible con esta app.',
      );
    }

    final rawBackupFormatVersion = _readInt(app['backup_format_version']);
    final backupFormatVersion =
        rawBackupFormatVersion ?? currentBackupFormatVersion;
    if (backupFormatVersion != currentBackupFormatVersion) {
      throw FormatException(
        'La versión del formato del respaldo ($backupFormatVersion) no es compatible.',
      );
    }

    final warnings = <String>[];
    if (rawBackupFormatVersion == null) {
      warnings.add(
        'Se detectó un respaldo legado. Finaper aplicará compatibilidad automática.',
      );
    }

    if (!payload.containsKey('transaction_form_preferences')) {
      warnings.add(
        'Este respaldo no incluye preferencias rápidas del formulario. Se restaurarán con valores por defecto.',
      );
    }

    final preview = BackupRestorePreviewEntity(
      fileName: fileName,
      exportedAt: DateTime.tryParse(
        normalizedPayload['exported_at']?.toString() ?? '',
      ),
      databaseVersion: databaseVersion,
      backupFormatVersion: backupFormatVersion,
      accountsCount: _normalizeRows(normalizedPayload['accounts']).length,
      categoriesCount: _normalizeRows(normalizedPayload['categories']).length,
      transactionsCount:
          _normalizeRows(normalizedPayload['transactions']).length,
      budgetsCount: _normalizeRows(normalizedPayload['budgets']).length,
      goalsCount: _normalizeRows(normalizedPayload['goals']).length,
      recurringTransactionsCount: _normalizeRows(
        normalizedPayload['recurring_transactions'],
      ).length,
      hasTransactionFormPreferences:
          _readMap(normalizedPayload['transaction_form_preferences'])
              .isNotEmpty,
    );

    return BackupValidationResultEntity(
      preview: preview,
      payload: normalizedPayload,
      warnings: warnings,
    );
  }

  Map<String, dynamic> normalizePayload(Map<String, dynamic> payload) {
    return <String, dynamic>{
      'exported_at': payload['exported_at'],
      'app': _readMap(payload['app']),
      'summary': _readMap(payload['summary']),
      'settings': _readMap(payload['settings']),
      'transaction_form_preferences':
          _readMap(payload['transaction_form_preferences']),
      'accounts': _normalizeAccounts(payload['accounts']),
      'categories': _normalizeRows(payload['categories']),
      'transactions': _normalizeRows(payload['transactions']),
      'budgets': _normalizeRows(payload['budgets']),
      'goals': _normalizeRows(payload['goals']),
      'recurring_transactions': _normalizeRows(
        payload['recurring_transactions'],
      ),
    };
  }

  List<Map<String, dynamic>> normalizeAccountsForRestore(Object? raw) {
    return _normalizeAccounts(raw);
  }

  Map<String, dynamic> ensureAppSettingsRow(Map<String, dynamic> row) {
    final now = DateTime.now().toIso8601String();

    return <String, dynamic>{
      'id': 1,
      'currency_code':
          row['currency_code']?.toString().trim().isNotEmpty == true
              ? row['currency_code']
              : 'CLP',
      'locale_code': row['locale_code']?.toString().trim().isNotEmpty == true
          ? row['locale_code']
          : 'es_CL',
      'use_system_locale': _readInt(row['use_system_locale']) ?? 1,
      'updated_at': row['updated_at']?.toString().trim().isNotEmpty == true
          ? row['updated_at']
          : now,
    };
  }

  Map<String, dynamic> ensureTransactionFormPreferencesRow(
    Map<String, dynamic> row,
  ) {
    return <String, dynamic>{
      'id': 1,
      'last_account_id': row['last_account_id'],
      'last_expense_category_id': row['last_expense_category_id'],
      'last_income_category_id': row['last_income_category_id'],
      'last_quick_date_option': row['last_quick_date_option'],
    };
  }

  List<Map<String, dynamic>> normalizeRowsForRestore(Object? raw) {
    return _normalizeRows(raw);
  }

  Map<String, dynamic> readMapForRestore(Object? raw) {
    return _readMap(raw);
  }

  List<Map<String, dynamic>> _normalizeAccounts(Object? raw) {
    return _normalizeRows(raw).map((row) {
      return <String, dynamic>{
        ...row,
        'initial_balance': (row['initial_balance'] as num? ?? 0).toDouble(),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _normalizeRows(Object? raw) {
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    return raw
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Map<String, dynamic> _readMap(Object? raw) {
    if (raw is! Map) {
      return <String, dynamic>{};
    }

    return Map<String, dynamic>.from(raw);
  }

  int? _readInt(Object? raw) {
    if (raw is int) {
      return raw;
    }

    if (raw is num) {
      return raw.toInt();
    }

    return int.tryParse(raw?.toString() ?? '');
  }

  void _ensureRequiredKey(
    Map<String, dynamic> payload,
    String key,
    String message,
  ) {
    if (!payload.containsKey(key)) {
      throw FormatException(message);
    }
  }
}
