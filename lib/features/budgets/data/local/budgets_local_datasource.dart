import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../transactions/domain/entities/transaction_entry_type.dart';
import '../models/budget_model.dart';

abstract class BudgetsLocalDataSource {
  Future<List<BudgetModel>> getBudgetsByMonth({
    required String monthKey,
  });

  Future<BudgetModel> upsertBudget(BudgetModel budget);

  Future<void> deleteBudget(String id);
}

class BudgetsLocalDataSourceImpl implements BudgetsLocalDataSource {
  const BudgetsLocalDataSourceImpl(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<BudgetModel>> getBudgetsByMonth({
    required String monthKey,
  }) async {
    try {
      final db = await _databaseHelper.database;

      final budgets = await db.query(
        'budgets',
        where: 'month_key = ?',
        whereArgs: [monthKey],
        orderBy: 'category_name ASC',
      );

      final result = <BudgetModel>[];

      for (final budget in budgets) {
        final categoryId = budget['category_id']?.toString() ?? '';
        final spentAmount = await _getSpentAmountForCategoryMonth(
          db,
          categoryId: categoryId,
          monthKey: monthKey,
        );

        result.add(
          BudgetModel.fromMap(
            budget,
            spentAmount: spentAmount,
          ),
        );
      }

      return result;
    } catch (e, s) {
      debugPrint('getBudgetsByMonth error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<BudgetModel> upsertBudget(BudgetModel budget) async {
    try {
      final db = await _databaseHelper.database;
      final existing = await db.query(
        'budgets',
        where: 'category_id = ? AND month_key = ?',
        whereArgs: [budget.categoryId, budget.monthKey],
        limit: 1,
      );

      final now = DateTime.now();

      if (existing.isEmpty) {
        final createModel = BudgetModel(
          id: budget.id,
          categoryId: budget.categoryId,
          categoryName: budget.categoryName,
          monthKey: budget.monthKey,
          amountLimit: budget.amountLimit,
          spentAmount: budget.spentAmount,
          color: budget.color,
          createdAt: budget.createdAt,
          updatedAt: now,
        );

        await db.insert(
          'budgets',
          createModel.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        return createModel;
      }

      final existingId = existing.first['id']?.toString() ?? budget.id;
      final existingCreatedAt = DateTime.tryParse(
            existing.first['created_at']?.toString() ?? '',
          ) ??
          budget.createdAt;

      final updateModel = BudgetModel(
        id: existingId,
        categoryId: budget.categoryId,
        categoryName: budget.categoryName,
        monthKey: budget.monthKey,
        amountLimit: budget.amountLimit,
        spentAmount: budget.spentAmount,
        color: budget.color,
        createdAt: existingCreatedAt,
        updatedAt: now,
      );

      await db.update(
        'budgets',
        updateModel.toMap(),
        where: 'id = ?',
        whereArgs: [existingId],
      );

      return updateModel;
    } catch (e, s) {
      debugPrint('upsertBudget error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    final db = await _databaseHelper.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> _getSpentAmountForCategoryMonth(
    Database db, {
    required String categoryId,
    required String monthKey,
  }) async {
    final range = _monthRangeFromKey(monthKey);

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE category_id = ?
        AND is_income = 0
        AND entry_type = ?
        AND date >= ?
        AND date < ?
      ''',
      [
        categoryId,
        TransactionEntryType.standard.storageValue,
        range.start.toIso8601String(),
        range.end.toIso8601String(),
      ],
    );

    return (result.first['total'] as num? ?? 0).toDouble();
  }

  _MonthRange _monthRangeFromKey(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    final start = DateTime(year, month);
    final end = month == 12 ? DateTime(year + 1, 1) : DateTime(year, month + 1);

    return _MonthRange(start: start, end: end);
  }
}

class _MonthRange {
  const _MonthRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}
