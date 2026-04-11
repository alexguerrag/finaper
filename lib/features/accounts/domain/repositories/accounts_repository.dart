import '../entities/account_balance_entity.dart';
import '../entities/account_entity.dart';

abstract class AccountsRepository {
  Future<List<AccountEntity>> getAccounts({
    bool includeArchived = false,
  });

  Future<List<AccountBalanceEntity>> getAccountBalances({
    bool includeArchived = false,
  });

  Future<AccountEntity> createAccount(AccountEntity account);

  Future<AccountEntity> updateAccount(AccountEntity account);
}
