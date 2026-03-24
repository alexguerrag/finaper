import '../entities/account_entity.dart';

abstract class AccountsRepository {
  Future<List<AccountEntity>> getAccounts({
    bool includeArchived = false,
  });
}
