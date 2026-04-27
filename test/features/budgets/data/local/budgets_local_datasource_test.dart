import 'package:finaper/core/database/database_helper.dart';
import 'package:finaper/features/budgets/data/local/budgets_local_datasource.dart';
import 'package:finaper/features/budgets/data/models/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

Future<Database> _openInMemoryDb() async {
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

  await db.execute('''
    CREATE TABLE budgets (
      id TEXT PRIMARY KEY,
      category_id TEXT NOT NULL,
      category_name TEXT NOT NULL,
      month_key TEXT NOT NULL,
      amount_limit REAL NOT NULL,
      color_value INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      UNIQUE(category_id, month_key)
    )
  ''');

  await db.execute('''
    CREATE TABLE transactions (
      id TEXT PRIMARY KEY,
      account_id TEXT NOT NULL,
      account_name TEXT NOT NULL,
      description TEXT NOT NULL,
      category_id TEXT NOT NULL,
      category TEXT NOT NULL,
      amount REAL NOT NULL,
      is_income INTEGER NOT NULL DEFAULT 0,
      entry_type TEXT NOT NULL DEFAULT 'standard',
      date TEXT NOT NULL,
      created_at TEXT NOT NULL,
      note TEXT NOT NULL DEFAULT '',
      color_value INTEGER NOT NULL DEFAULT 0,
      transfer_group_id TEXT,
      counterparty_account_id TEXT,
      counterparty_account_name TEXT
    )
  ''');

  return db;
}

BudgetModel _budget({
  required String id,
  required String categoryId,
  required String categoryName,
  required String monthKey,
  double amountLimit = 500,
}) {
  final now = DateTime(2026, 4, 1);
  return BudgetModel(
    id: id,
    categoryId: categoryId,
    categoryName: categoryName,
    monthKey: monthKey,
    amountLimit: amountLimit,
    spentAmount: 0,
    color: Colors.grey,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _insertTx(
  Database db, {
  required String id,
  required String categoryId,
  required double amount,
  required bool isIncome,
  required String date,
  String entryType = 'standard',
}) async {
  await db.insert('transactions', {
    'id': id,
    'account_id': 'acc1',
    'account_name': 'Cuenta 1',
    'description': 'Test',
    'category_id': categoryId,
    'category': 'Cat',
    'amount': amount,
    'is_income': isIncome ? 1 : 0,
    'entry_type': entryType,
    'date': date,
    'created_at': date,
    'note': '',
    'color_value': 0,
  });
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  late Database db;
  late BudgetsLocalDataSourceImpl datasource;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await _openInMemoryDb();
    DatabaseHelper.instance.overrideForTest(db);
    datasource = BudgetsLocalDataSourceImpl(DatabaseHelper.instance);
  });

  tearDown(() async {
    DatabaseHelper.resetForTest();
    await db.close();
  });

  group('BudgetsLocalDataSource — getBudgetsByMonth', () {
    const monthKey = '2026-04';

    test('returns empty list when no budgets exist', () async {
      final result = await datasource.getBudgetsByMonth(monthKey: monthKey);
      expect(result, isEmpty);
    });

    test('returns spentAmount=0 when no transactions exist', () async {
      await datasource.upsertBudget(
        _budget(
            id: 'b1',
            categoryId: 'cat1',
            categoryName: 'Food',
            monthKey: monthKey),
      );
      final result = await datasource.getBudgetsByMonth(monthKey: monthKey);
      expect(result.length, 1);
      expect(result.first.spentAmount, 0.0);
    });

    test('calculates spentAmount correctly', () async {
      await datasource.upsertBudget(
        _budget(
            id: 'b1',
            categoryId: 'cat1',
            categoryName: 'Food',
            monthKey: monthKey),
      );
      await _insertTx(db,
          id: 't1',
          categoryId: 'cat1',
          amount: 150,
          isIncome: false,
          date: '2026-04-10T00:00:00.000');
      await _insertTx(db,
          id: 't2',
          categoryId: 'cat1',
          amount: 80,
          isIncome: false,
          date: '2026-04-20T00:00:00.000');

      final result = await datasource.getBudgetsByMonth(monthKey: monthKey);
      expect(result.first.spentAmount, 230.0);
    });

    test('ignores income transactions', () async {
      await datasource.upsertBudget(
        _budget(
            id: 'b1',
            categoryId: 'cat1',
            categoryName: 'Food',
            monthKey: monthKey),
      );
      await _insertTx(db,
          id: 't1',
          categoryId: 'cat1',
          amount: 500,
          isIncome: true,
          date: '2026-04-10T00:00:00.000');
      await _insertTx(db,
          id: 't2',
          categoryId: 'cat1',
          amount: 100,
          isIncome: false,
          date: '2026-04-10T00:00:00.000');

      final result = await datasource.getBudgetsByMonth(monthKey: monthKey);
      expect(result.first.spentAmount, 100.0);
    });

    test('ignores transactions from other months', () async {
      await datasource.upsertBudget(
        _budget(
            id: 'b1',
            categoryId: 'cat1',
            categoryName: 'Food',
            monthKey: monthKey),
      );
      await _insertTx(db,
          id: 't1',
          categoryId: 'cat1',
          amount: 200,
          isIncome: false,
          date: '2026-03-31T00:00:00.000');
      await _insertTx(db,
          id: 't2',
          categoryId: 'cat1',
          amount: 100,
          isIncome: false,
          date: '2026-04-01T00:00:00.000');

      final result = await datasource.getBudgetsByMonth(monthKey: monthKey);
      expect(result.first.spentAmount, 100.0);
    });

    test('handles multiple budgets with correct per-category aggregation',
        () async {
      await datasource.upsertBudget(
        _budget(
            id: 'b1',
            categoryId: 'cat1',
            categoryName: 'Food',
            monthKey: monthKey),
      );
      await datasource.upsertBudget(
        _budget(
            id: 'b2',
            categoryId: 'cat2',
            categoryName: 'Transport',
            monthKey: monthKey),
      );
      await _insertTx(db,
          id: 't1',
          categoryId: 'cat1',
          amount: 300,
          isIncome: false,
          date: '2026-04-05T00:00:00.000');
      await _insertTx(db,
          id: 't2',
          categoryId: 'cat1',
          amount: 50,
          isIncome: false,
          date: '2026-04-06T00:00:00.000');
      await _insertTx(db,
          id: 't3',
          categoryId: 'cat2',
          amount: 120,
          isIncome: false,
          date: '2026-04-07T00:00:00.000');

      final result = await datasource.getBudgetsByMonth(monthKey: monthKey);
      final food = result.firstWhere((b) => b.categoryId == 'cat1');
      final transport = result.firstWhere((b) => b.categoryId == 'cat2');
      expect(food.spentAmount, 350.0);
      expect(transport.spentAmount, 120.0);
    });

    test('ignores transfer_out entry_type in spent calculation', () async {
      await datasource.upsertBudget(
        _budget(
            id: 'b1',
            categoryId: 'cat1',
            categoryName: 'Food',
            monthKey: monthKey),
      );
      await _insertTx(db,
          id: 't1',
          categoryId: 'cat1',
          amount: 200,
          isIncome: false,
          date: '2026-04-10T00:00:00.000',
          entryType: 'transfer_out');
      await _insertTx(db,
          id: 't2',
          categoryId: 'cat1',
          amount: 100,
          isIncome: false,
          date: '2026-04-10T00:00:00.000',
          entryType: 'standard');

      final result = await datasource.getBudgetsByMonth(monthKey: monthKey);
      expect(result.first.spentAmount, 100.0);
    });

    test('5 budgets resolved correctly with single aggregation query',
        () async {
      for (var i = 1; i <= 5; i++) {
        await datasource.upsertBudget(
          _budget(
              id: 'b$i',
              categoryId: 'cat$i',
              categoryName: 'Cat $i',
              monthKey: monthKey),
        );
        await _insertTx(db,
            id: 't$i',
            categoryId: 'cat$i',
            amount: i * 10.0,
            isIncome: false,
            date: '2026-04-10T00:00:00.000');
      }

      final result = await datasource.getBudgetsByMonth(monthKey: monthKey);
      expect(result.length, 5);
      for (var i = 1; i <= 5; i++) {
        final budget = result.firstWhere((b) => b.categoryId == 'cat$i');
        expect(budget.spentAmount, i * 10.0);
      }
    });
  });
}
