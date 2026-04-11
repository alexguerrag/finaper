import '../entities/account_balance_entity.dart';
import '../repositories/accounts_repository.dart';

class GetAccountBalances {
  const GetAccountBalances(this._repository);

  final AccountsRepository _repository;

  Future<List<AccountBalanceEntity>> call({
    bool includeArchived = false,
  }) {
    return _repository.getAccountBalances(
      includeArchived: includeArchived,
    );
  }
}
