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

      // Fetch all category spending for the month in a single aggregation
      // query instead of one query per budget (eliminates N+1).
      final categoryIds = budgets
          .map((b) => b['category_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      final spentByCategory = await _getSpentAmountsByCategories(
        db,
        categoryIds: categoryIds,
        monthKey: monthKey,
      );

      return budgets.map((budget) {
        final categoryId = budget['category_id']?.toString() ?? '';
        return BudgetModel.fromMap(
          budget,
          spentAmount: spentByCategory[categoryId] ?? 0.0,
        );
      }).toList();
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

  /// Single GROUP BY query — replaces the old per-category N+1 loop.
  Future<Map<String, double>> _getSpentAmountsByCategories(
    Database db, {
    required List<String> categoryIds,
    required String monthKey,
  }) async {
    if (categoryIds.isEmpty) return {};

    final range = _monthRangeFromKey(monthKey);
    final placeholders = categoryIds.map((_) => '?').join(', ');

    final rows = await db.rawQuery(
      '''
      SELECT category_id, COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE category_id IN ($placeholders)
        AND is_income = 0
        AND entry_type = ?
        AND date >= ?
        AND date < ?
      GROUP BY category_id
      ''',
      [
        ...categoryIds,
        TransactionEntryType.standard.storageValue,
        range.start.toIso8601String(),
        range.end.toIso8601String(),
      ],
    );

    return {
      for (final row in rows)
        row['category_id'].toString(): (row['total'] as num? ?? 0).toDouble(),
    };
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
