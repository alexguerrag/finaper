import '../../../../core/database/database_helper.dart';
import '../models/account_model.dart';

abstract class AccountsLocalDataSource {
  Future<List<AccountModel>> getAccounts({
    bool includeArchived = false,
  });
}

class AccountsLocalDataSourceImpl implements AccountsLocalDataSource {
  const AccountsLocalDataSourceImpl(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<AccountModel>> getAccounts({
    bool includeArchived = false,
  }) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'accounts',
      where: includeArchived ? null : 'is_archived = ?',
      whereArgs: includeArchived ? null : [0],
      orderBy: 'name ASC',
    );

    return result.map(AccountModel.fromMap).toList();
  }
}
