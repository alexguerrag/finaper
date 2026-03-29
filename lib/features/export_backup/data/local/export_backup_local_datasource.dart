import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/export_file_model.dart';

abstract class ExportBackupLocalDataSource {
  Future<ExportFileModel> exportBackupJson();

  Future<ExportFileModel> exportTransactionsCsv();
}

class ExportBackupLocalDataSourceImpl implements ExportBackupLocalDataSource {
  const ExportBackupLocalDataSourceImpl(this._databaseHelper);

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

      final payload = <String, dynamic>{
        'exported_at': now.toIso8601String(),
        'app': <String, dynamic>{
          'name': 'Finaper',
          'database_version': 7,
          'format': 'json-backup',
        },
        'settings': await _querySingleOrEmpty(db, 'app_settings'),
        'accounts': await db.query(
          'accounts',
          orderBy: 'created_at DESC',
        ),
        'categories': await db.query(
          'categories',
          orderBy: 'kind ASC, name ASC',
        ),
        'transactions': await db.query(
          'transactions',
          orderBy: 'date DESC',
        ),
        'budgets': await db.query(
          'budgets',
          orderBy: 'month_key DESC, category_name ASC',
        ),
        'goals': await db.query(
          'goals',
          orderBy: 'updated_at DESC',
        ),
        'recurring_transactions': await db.query(
          'recurring_transactions',
          orderBy: 'updated_at DESC',
        ),
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
