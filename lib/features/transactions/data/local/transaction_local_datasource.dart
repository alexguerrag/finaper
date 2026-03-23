import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<TransactionModel> insertTransaction(TransactionModel transaction);
  Future<TransactionModel> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  const TransactionLocalDataSourceImpl(this.dbHelper);

  final DatabaseHelper dbHelper;

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        orderBy: 'date DESC',
      );

      return List<TransactionModel>.generate(
        maps.length,
        (index) => TransactionModel.fromMap(maps[index]),
      );
    } catch (e, s) {
      debugPrint('getTransactions error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<TransactionModel> insertTransaction(
    TransactionModel transaction,
  ) async {
    try {
      final db = await dbHelper.database;

      await db.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return transaction;
    } catch (e, s) {
      debugPrint('insertTransaction datasource error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
    TransactionModel transaction,
  ) async {
    try {
      final db = await dbHelper.database;

      await db.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      return transaction;
    } catch (e, s) {
      debugPrint('updateTransaction datasource error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      final db = await dbHelper.database;

      await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, s) {
      debugPrint('deleteTransaction datasource error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
