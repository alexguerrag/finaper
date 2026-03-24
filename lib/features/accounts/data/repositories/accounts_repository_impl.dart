import '../../domain/entities/account_entity.dart';
import '../../domain/repositories/accounts_repository.dart';
import '../local/accounts_local_datasource.dart';
import '../models/account_model.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  const AccountsRepositoryImpl(this._localDataSource);

  final AccountsLocalDataSource _localDataSource;

  @override
  Future<List<AccountEntity>> getAccounts({
    bool includeArchived = false,
  }) {
    return _localDataSource.getAccounts(
      includeArchived: includeArchived,
    );
  }

  @override
  Future<AccountEntity> createAccount(AccountEntity account) {
    return _localDataSource.createAccount(
      AccountModel.fromEntity(account),
    );
  }
}
