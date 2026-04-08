import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/transaction_form_preferences_model.dart';

abstract class TransactionFormPreferencesLocalDataSource {
  Future<TransactionFormPreferencesModel> getPreferences();
  Future<void> savePreferences(TransactionFormPreferencesModel preferences);
}

class TransactionFormPreferencesLocalDataSourceImpl
    implements TransactionFormPreferencesLocalDataSource {
  const TransactionFormPreferencesLocalDataSourceImpl(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  @override
  Future<TransactionFormPreferencesModel> getPreferences() async {
    try {
      final db = await _databaseHelper.database;

      final result = await db.query(
        'transaction_form_preferences',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (result.isEmpty) {
        return const TransactionFormPreferencesModel();
      }

      return TransactionFormPreferencesModel.fromMap(result.first);
    } catch (e, s) {
      debugPrint('get transaction form preferences error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> savePreferences(
    TransactionFormPreferencesModel preferences,
  ) async {
    try {
      final db = await _databaseHelper.database;

      await db.insert(
        'transaction_form_preferences',
        preferences.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, s) {
      debugPrint('save transaction form preferences error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
