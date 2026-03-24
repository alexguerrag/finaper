import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/account_model.dart';

abstract class AccountsLocalDataSource {
  Future<List<AccountModel>> getAccounts({
    bool includeArchived = false,
  });

  Future<AccountModel> createAccount(AccountModel account);
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
}
