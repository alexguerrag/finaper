import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/backup_restore_preview_entity.dart';
import '../../domain/entities/backup_validation_result_entity.dart';
import '../models/export_file_model.dart';

abstract class ExportBackupLocalDataSource {
  Future<ExportFileModel> exportBackupJson();

  Future<ExportFileModel> exportTransactionsCsv();

  Future<BackupValidationResultEntity?> pickBackupRestorePreview();

  Future<void> restoreBackupJson(Map<String, dynamic> payload);
}

class ExportBackupLocalDataSourceImpl implements ExportBackupLocalDataSource {
  const ExportBackupLocalDataSourceImpl(this._databaseHelper);

  static const int _currentDatabaseVersion = 9;
  static const int _currentBackupFormatVersion = 1;

  final DatabaseHelper _databaseHelper;

  @override
  Future<ExportFileModel> exportBackupJson() async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now();
      final exportDir = await _ensureExportDirectory();
      final timestamp = _fileTimestamp(now);
      final fileName = 'finaper_backup_$timestamp.json';
      final filePath = p.join(exportDir.path, fileName);

      final settings = await _querySingleOrEmpty(db, 'app_settings');
      final transactionFormPreferences = await _querySingleOrEmpty(
        db,
        'transaction_form_preferences',
      );
      final accounts = await db.query(
        'accounts',
        orderBy: 'created_at DESC',
      );
      final categories = await db.query(
        'categories',
        orderBy: 'kind ASC, name ASC',
      );
      final transactions = await db.query(
        'transactions',
        orderBy: 'date DESC',
      );
      final budgets = await db.query(
        'budgets',
        orderBy: 'month_key DESC, category_name ASC',
      );
      final goals = await db.query(
        'goals',
        orderBy: 'updated_at DESC',
      );
      final recurringTransactions = await db.query(
        'recurring_transactions',
        orderBy: 'updated_at DESC',
      );

      final payload = <String, dynamic>{
        'exported_at': now.toIso8601String(),
        'app': <String, dynamic>{
          'name': 'Finaper',
          'database_version': _currentDatabaseVersion,
          'backup_format_version': _currentBackupFormatVersion,
          'format': 'json-backup',
        },
        'summary': <String, dynamic>{
          'accounts_count': accounts.length,
          'categories_count': categories.length,
          'transactions_count': transactions.length,
          'budgets_count': budgets.length,
          'goals_count': goals.length,
          'recurring_transactions_count': recurringTransactions.length,
          'has_transaction_form_preferences':
              transactionFormPreferences.isNotEmpty,
        },
        'settings': settings,
        'transaction_form_preferences': transactionFormPreferences,
        'accounts': accounts,
        'categories': categories,
        'transactions': transactions,
        'budgets': budgets,
        'goals': goals,
        'recurring_transactions': recurringTransactions,
      };

      const encoder = JsonEncoder.withIndent('  ');
      final content = encoder.convert(payload);

      final file = File(filePath);
      await file.writeAsString(content, flush: true);

      return ExportFileModel(
        fileName: fileName,
        filePath: filePath,
        mimeType: 'application/json',
        createdAt: now,
      );
    } catch (e, s) {
      debugPrint('exportBackupJson error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<ExportFileModel> exportTransactionsCsv() async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now();
      final exportDir = await _ensureExportDirectory();
      final timestamp = _fileTimestamp(now);
      final fileName = 'finaper_transactions_$timestamp.csv';
      final filePath = p.join(exportDir.path, fileName);

      final rows = await db.query(
        'transactions',
        orderBy: 'date DESC',
      );

      final buffer = StringBuffer();
      buffer.writeln(
        [
          'id',
          'date',
          'description',
          'category',
          'category_id',
          'account_name',
          'account_id',
          'amount',
          'is_income',
          'note',
          'generated_from_recurring_id',
        ].join(','),
      );

      for (final row in rows) {
        buffer.writeln(
          [
            _csv(row['id']),
            _csv(row['date']),
            _csv(row['description']),
            _csv(row['category']),
            _csv(row['category_id']),
            _csv(row['account_name']),
            _csv(row['account_id']),
            _csv(row['amount']),
            _csv(row['is_income']),
            _csv(row['note']),
            _csv(row['generated_from_recurring_id']),
          ].join(','),
        );
      }

      final file = File(filePath);
      await file.writeAsString(buffer.toString(), flush: true);

      return ExportFileModel(
        fileName: fileName,
        filePath: filePath,
        mimeType: 'text/csv',
        createdAt: now,
      );
    } catch (e, s) {
      debugPrint('exportTransactionsCsv error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<BackupValidationResultEntity?> pickBackupRestorePreview() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final pickedFile = result.files.single;
      final rawContent = await _readPickedFileContent(pickedFile);

      return _parseAndValidatePayload(
        fileName: pickedFile.name,
        rawContent: rawContent,
      );
    } catch (e, s) {
      debugPrint('pickBackupRestorePreview error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> restoreBackupJson(Map<String, dynamic> payload) async {
    try {
      final normalized = _normalizePayload(payload);
      final db = await _databaseHelper.database;

      await db.transaction((txn) async {
        await txn.delete('transactions');
        await txn.delete('recurring_transactions');
        await txn.delete('budgets');
        await txn.delete('goals');
        await txn.delete('categories');
        await txn.delete('accounts');
        await txn.delete('app_settings');
        await txn.delete('transaction_form_preferences');

        final settings = _ensureAppSettingsRow(
          _readMap(normalized['settings']),
        );
        final formPreferences = _ensureTransactionFormPreferencesRow(
          _readMap(normalized['transaction_form_preferences']),
        );
        final accounts = _normalizeAccounts(normalized['accounts']);
        final categories = _normalizeRows(normalized['categories']);
        final goals = _normalizeRows(normalized['goals']);
        final budgets = _normalizeRows(normalized['budgets']);
        final recurringTransactions = _normalizeRows(
          normalized['recurring_transactions'],
        );
        final transactions = _normalizeRows(normalized['transactions']);

        await txn.insert(
          'app_settings',
          settings,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.insert(
          'transaction_form_preferences',
          formPreferences,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await _insertMany(txn, 'accounts', accounts);
        await _insertMany(txn, 'categories', categories);
        await _insertMany(txn, 'goals', goals);
        await _insertMany(txn, 'budgets', budgets);
        await _insertMany(txn, 'recurring_transactions', recurringTransactions);
        await _insertMany(txn, 'transactions', transactions);
      });
    } catch (e, s) {
      debugPrint('restoreBackupJson error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<void> _insertMany(
    Transaction txn,
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      await txn.insert(
        table,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<String> _readPickedFileContent(PlatformFile pickedFile) async {
    final bytes = pickedFile.bytes;
    if (bytes != null) {
      return utf8.decode(bytes);
    }

    final path = pickedFile.path;
    if (path == null || path.isEmpty) {
      throw const FormatException(
        'No se pudo leer el archivo seleccionado.',
      );
    }

    return File(path).readAsString();
  }

  BackupValidationResultEntity _parseAndValidatePayload({
    required String fileName,
    required String rawContent,
  }) {
    final decoded = jsonDecode(rawContent);

    if (decoded is! Map) {
      throw const FormatException(
        'El archivo seleccionado no tiene un formato de respaldo válido.',
      );
    }

    final payload = _normalizePayload(Map<String, dynamic>.from(decoded));
    final app = _readMap(payload['app']);

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
    if (databaseVersion < 7 || databaseVersion > _currentDatabaseVersion) {
      throw FormatException(
        'La versión del respaldo ($databaseVersion) no es compatible con esta app.',
      );
    }

    final rawBackupFormatVersion = _readInt(app['backup_format_version']);
    final backupFormatVersion = rawBackupFormatVersion ?? 1;
    if (backupFormatVersion != 1) {
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

    if (!_hasKey(payload, 'transaction_form_preferences')) {
      warnings.add(
        'Este respaldo no incluye preferencias rápidas del formulario. Se restaurarán con valores por defecto.',
      );
    }

    final preview = BackupRestorePreviewEntity(
      fileName: fileName,
      exportedAt: DateTime.tryParse(
        payload['exported_at']?.toString() ?? '',
      ),
      databaseVersion: databaseVersion,
      backupFormatVersion: backupFormatVersion,
      accountsCount: _normalizeRows(payload['accounts']).length,
      categoriesCount: _normalizeRows(payload['categories']).length,
      transactionsCount: _normalizeRows(payload['transactions']).length,
      budgetsCount: _normalizeRows(payload['budgets']).length,
      goalsCount: _normalizeRows(payload['goals']).length,
      recurringTransactionsCount: _normalizeRows(
        payload['recurring_transactions'],
      ).length,
      hasTransactionFormPreferences:
          _readMap(payload['transaction_form_preferences']).isNotEmpty,
    );

    return BackupValidationResultEntity(
      preview: preview,
      payload: payload,
      warnings: warnings,
    );
  }

  Map<String, dynamic> _normalizePayload(Map<String, dynamic> payload) {
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

  bool _hasKey(Map<String, dynamic> map, String key) {
    return map.containsKey(key);
  }

  Map<String, dynamic> _ensureAppSettingsRow(Map<String, dynamic> row) {
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

  Map<String, dynamic> _ensureTransactionFormPreferencesRow(
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

  Future<Directory> _ensureExportDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(
      p.join(documentsDir.path, 'finaper_exports'),
    );

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    return exportDir;
  }

  Future<Map<String, dynamic>> _querySingleOrEmpty(
    Database db,
    String table,
  ) async {
    final result = await db.query(
      table,
      limit: 1,
    );

    if (result.isEmpty) {
      return <String, dynamic>{};
    }

    return Map<String, dynamic>.from(result.first);
  }

  String _fileTimestamp(DateTime value) {
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    final ss = value.second.toString().padLeft(2, '0');

    return '$yyyy$mm${dd}_$hh$min$ss';
  }

  String _csv(Object? value) {
    final raw = value?.toString() ?? '';
    final escaped = raw.replaceAll('"', '""');
    return '"$escaped"';
  }
}
