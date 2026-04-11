import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/account_balance_entity.dart';
import '../models/account_model.dart';

abstract class AccountsLocalDataSource {
  Future<List<AccountModel>> getAccounts({
    bool includeArchived = false,
  });

  Future<List<AccountBalanceEntity>> getAccountBalances({
    bool includeArchived = false,
  });

  Future<AccountModel> createAccount(AccountModel account);

  Future<AccountModel> updateAccount(AccountModel account);
}

class AccountsLocalDataSourceImpl implements AccountsLocalDataSource {
  const AccountsLocalDataSourceImpl(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<AccountModel>> getAccounts({
    bool includeArchived = false,
  }) async {
    try {
      final db = await _databaseHelper.database;

      final result = await db.query(
        'accounts',
        where: includeArchived ? null : 'is_archived = ?',
        whereArgs: includeArchived ? null : [0],
        orderBy: 'name ASC',
      );

      return result.map(AccountModel.fromMap).toList();
    } catch (e, s) {
      debugPrint('getAccounts error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<List<AccountBalanceEntity>> getAccountBalances({
    bool includeArchived = false,
  }) async {
    try {
      final db = await _databaseHelper.database;
      final accounts = await getAccounts(includeArchived: includeArchived);

      final flowRows = await db.rawQuery('''
        SELECT
          account_id,
          COALESCE(SUM(CASE WHEN is_income = 1 THEN amount ELSE 0 END), 0) AS total_income,
          COALESCE(SUM(CASE WHEN is_income = 0 THEN amount ELSE 0 END), 0) AS total_expense
        FROM transactions
        GROUP BY account_id
      ''');

      final flowByAccountId = <String, _AccountFlowAccumulator>{};

      for (final row in flowRows) {
        final accountId = row['account_id']?.toString();
        if (accountId == null || accountId.isEmpty) {
          continue;
        }

        flowByAccountId[accountId] = _AccountFlowAccumulator(
          totalIncome: (row['total_income'] as num? ?? 0).toDouble(),
          totalExpense: (row['total_expense'] as num? ?? 0).toDouble(),
        );
      }

      return accounts.map((account) {
        final flow = flowByAccountId[account.id];

        return AccountBalanceEntity(
          account: account,
          totalIncome: flow?.totalIncome ?? 0,
          totalExpense: flow?.totalExpense ?? 0,
        );
      }).toList();
    } catch (e, s) {
      debugPrint('getAccountBalances error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<AccountModel> createAccount(AccountModel account) async {
    try {
      final db = await _databaseHelper.database;

      await db.insert(
        'accounts',
        account.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return account;
    } catch (e, s) {
      debugPrint('createAccount error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<AccountModel> updateAccount(AccountModel account) async {
    try {
      final db = await _databaseHelper.database;

      await db.update(
        'accounts',
        account.toMap(),
        where: 'id = ?',
        whereArgs: [account.id],
      );

      return account;
    } catch (e, s) {
      debugPrint('updateAccount error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}

class _AccountFlowAccumulator {
  const _AccountFlowAccumulator({
    required this.totalIncome,
    required this.totalExpense,
  });

  final double totalIncome;
  final double totalExpense;
}
