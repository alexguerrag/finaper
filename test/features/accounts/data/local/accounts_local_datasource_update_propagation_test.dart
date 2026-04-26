import 'package:finaper/core/database/database_helper.dart';
import 'package:finaper/core/enums/account_type.dart';
import 'package:finaper/features/accounts/data/local/accounts_local_datasource.dart';
import 'package:finaper/features/accounts/data/models/account_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _openInMemoryDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

  await db.execute('''
    CREATE TABLE accounts (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      icon_code INTEGER NOT NULL,
      color_value INTEGER NOT NULL,
      initial_balance REAL NOT NULL DEFAULT 0,
      is_archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
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

  await db.execute('''
    CREATE TABLE recurring_transactions (
      id TEXT PRIMARY KEY,
      account_id TEXT NOT NULL,
      account_name TEXT NOT NULL,
      description TEXT NOT NULL,
      category_id TEXT NOT NULL,
      category_name TEXT NOT NULL,
      amount REAL NOT NULL,
      is_income INTEGER NOT NULL,
      note TEXT,
      color_value INTEGER NOT NULL,
      frequency TEXT NOT NULL,
      interval_value INTEGER NOT NULL DEFAULT 1,
      start_date TEXT NOT NULL,
      end_date TEXT,
      next_run_date TEXT NOT NULL,
      last_generated_date TEXT,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

  return db;
}

AccountModel _testAccount({String name = 'Cuenta Principal'}) => AccountModel(
      id: 'acc-test',
      name: name,
      type: AccountType.bank,
      iconCode: Icons.account_balance_rounded.codePoint,
      color: Colors.indigo,
      initialBalance: 500000,
      isArchived: false,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('AccountsLocalDataSourceImpl.updateAccount — name propagation', () {
    late Database db;
    late AccountsLocalDataSourceImpl datasource;

    setUp(() async {
      db = await _openInMemoryDb();
      final helper = DatabaseHelper.instance;
      helper.overrideForTest(db);
      datasource = AccountsLocalDataSourceImpl(helper);

      // Insert base account
      await db.insert('accounts', {
        'id': 'acc-test',
        'name': 'Cuenta Principal',
        'type': 'bank',
        'icon_code': Icons.account_balance_rounded.codePoint,
        'color_value': Colors.indigo.toARGB32(),
        'initial_balance': 500000.0,
        'is_archived': 0,
        'created_at': '2026-01-01T00:00:00.000',
      });

      // Regular transaction owned by the account
      await db.insert('transactions', {
        'id': 'txn-1',
        'account_id': 'acc-test',
        'account_name': 'Cuenta Principal',
        'description': 'Supermercado',
        'category_id': 'cat-food',
        'category': 'Alimentación',
        'amount': 20000.0,
        'is_income': 0,
        'entry_type': 'standard',
        'date': '2026-04-01',
        'created_at': '2026-04-01T10:00:00.000',
        'note': '',
        'color_value': 0,
      });

      // Transfer where this account is the counterparty
      await db.insert('transactions', {
        'id': 'txn-2',
        'account_id': 'acc-other',
        'account_name': 'Otra Cuenta',
        'description': 'Transferencia',
        'category_id': 'cat-transfer',
        'category': 'Transferencia',
        'amount': 50000.0,
        'is_income': 0,
        'entry_type': 'transfer_out',
        'date': '2026-04-02',
        'created_at': '2026-04-02T10:00:00.000',
        'note': '',
        'color_value': 0,
        'counterparty_account_id': 'acc-test',
        'counterparty_account_name': 'Cuenta Principal',
      });

      // Recurring transaction owned by the account
      await db.insert('recurring_transactions', {
        'id': 'rec-1',
        'account_id': 'acc-test',
        'account_name': 'Cuenta Principal',
        'description': 'Netflix',
        'category_id': 'cat-subs',
        'category_name': 'Suscripciones',
        'amount': 5990.0,
        'is_income': 0,
        'color_value': 0,
        'frequency': 'monthly',
        'interval_value': 1,
        'start_date': '2026-01-01',
        'next_run_date': '2026-05-01',
        'is_active': 1,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });
    });

    tearDown(() async {
      DatabaseHelper.resetForTest();
      await db.close();
    });

    test('actualiza account_name en transactions cuando se renombra la cuenta',
        () async {
      await datasource.updateAccount(_testAccount(name: 'Cuenta Pro'));

      final rows = await db.query(
        'transactions',
        where: 'account_id = ?',
        whereArgs: ['acc-test'],
      );
      expect(rows.first['account_name'], 'Cuenta Pro');
    });

    test('actualiza counterparty_account_name en transactions de transferencia',
        () async {
      await datasource.updateAccount(_testAccount(name: 'Cuenta Pro'));

      final rows = await db.query(
        'transactions',
        where: 'counterparty_account_id = ?',
        whereArgs: ['acc-test'],
      );
      expect(rows.first['counterparty_account_name'], 'Cuenta Pro');
    });

    test(
        'actualiza account_name en recurring_transactions cuando se renombra la cuenta',
        () async {
      await datasource.updateAccount(_testAccount(name: 'Cuenta Pro'));

      final rows = await db.query(
        'recurring_transactions',
        where: 'account_id = ?',
        whereArgs: ['acc-test'],
      );
      expect(rows.first['account_name'], 'Cuenta Pro');
    });

    test('no modifica transacciones de otras cuentas', () async {
      await datasource.updateAccount(_testAccount(name: 'Cuenta Pro'));

      final rows = await db.query(
        'transactions',
        where: 'account_id = ?',
        whereArgs: ['acc-other'],
      );
      expect(rows.first['account_name'], 'Otra Cuenta');
    });
  });
}
