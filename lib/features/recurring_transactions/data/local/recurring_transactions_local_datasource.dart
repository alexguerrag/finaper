import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/utils/recurrence_date_utils.dart';
import '../models/recurring_transaction_model.dart';

abstract class RecurringTransactionsLocalDataSource {
  Future<List<RecurringTransactionModel>> getRecurringTransactions({
    bool includeInactive = true,
  });

  Future<RecurringTransactionModel> createRecurringTransaction(
    RecurringTransactionModel recurringTransaction,
  );

  Future<RecurringTransactionModel> updateRecurringTransaction(
    RecurringTransactionModel recurringTransaction,
  );

  Future<int> syncDueRecurringTransactions();

  Future<void> deleteRecurringTransaction(String id);
}

class RecurringTransactionsLocalDataSourceImpl
    implements RecurringTransactionsLocalDataSource {
  const RecurringTransactionsLocalDataSourceImpl(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<RecurringTransactionModel>> getRecurringTransactions({
    bool includeInactive = true,
  }) async {
    try {
      final db = await _databaseHelper.database;

      final result = await db.query(
        'recurring_transactions',
        where: includeInactive ? null : 'is_active = ?',
        whereArgs: includeInactive ? null : [1],
        orderBy: 'is_active DESC, next_run_date ASC',
      );

      return result.map(RecurringTransactionModel.fromMap).toList();
    } catch (e, s) {
      debugPrint('getRecurringTransactions error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<RecurringTransactionModel> createRecurringTransaction(
    RecurringTransactionModel recurringTransaction,
  ) async {
    try {
      final db = await _databaseHelper.database;

      await db.insert(
        'recurring_transactions',
        recurringTransaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return recurringTransaction;
    } catch (e, s) {
      debugPrint('createRecurringTransaction error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<RecurringTransactionModel> updateRecurringTransaction(
    RecurringTransactionModel recurringTransaction,
  ) async {
    try {
      final db = await _databaseHelper.database;

      await db.update(
        'recurring_transactions',
        recurringTransaction.toMap(),
        where: 'id = ?',
        whereArgs: [recurringTransaction.id],
      );

      return recurringTransaction;
    } catch (e, s) {
      debugPrint('updateRecurringTransaction error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteRecurringTransaction(String id) async {
    try {
      final db = await _databaseHelper.database;

      await db.delete(
        'recurring_transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, s) {
      debugPrint('deleteRecurringTransaction error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<int> syncDueRecurringTransactions() async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now();
      int generatedCount = 0;

      await db.transaction((txn) async {
        final dueRows = await txn.query(
          'recurring_transactions',
          where: '''
            is_active = 1
            AND next_run_date <= ?
            AND (end_date IS NULL OR end_date = '' OR next_run_date <= end_date)
          ''',
          whereArgs: [now.toIso8601String()],
          orderBy: 'next_run_date ASC',
        );

        for (final row in dueRows) {
          final recurring = RecurringTransactionModel.fromMap(row);
          var currentRunDate = recurring.nextRunDate;
          DateTime? lastGeneratedDate = recurring.lastGeneratedDate;
          bool isActive = recurring.isActive;

          while (!currentRunDate.isAfter(now)) {
            if (recurring.endDate != null &&
                currentRunDate.isAfter(recurring.endDate!)) {
              isActive = false;
              break;
            }

            final transactionId =
                'rtx-${recurring.id}-${currentRunDate.millisecondsSinceEpoch}';

            await txn.insert(
              'transactions',
              {
                'id': transactionId,
                'account_id': recurring.accountId,
                'account_name': recurring.accountName,
                'description': recurring.description,
                'category_id': recurring.categoryId,
                'category': recurring.categoryName,
                'amount': recurring.amount,
                'is_income': recurring.isIncome ? 1 : 0,
                'date': currentRunDate.toIso8601String(),
                'note': recurring.note,
                'color_value': recurring.color.toARGB32(),
                'generated_from_recurring_id': recurring.id,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );

            generatedCount++;
            lastGeneratedDate = currentRunDate;

            currentRunDate = calculateNextOccurrence(
              currentRunDate,
              recurring.frequency,
              recurring.intervalValue,
            );
          }

          if (recurring.endDate != null &&
              currentRunDate.isAfter(recurring.endDate!)) {
            isActive = false;
          }

          await txn.update(
            'recurring_transactions',
            {
              'next_run_date': currentRunDate.toIso8601String(),
              'last_generated_date': lastGeneratedDate?.toIso8601String(),
              'is_active': isActive ? 1 : 0,
              'updated_at': now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [recurring.id],
          );
        }
      });

      return generatedCount;
    } catch (e, s) {
      debugPrint('syncDueRecurringTransactions error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
