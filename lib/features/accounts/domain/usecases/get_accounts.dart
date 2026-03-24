import '../entities/account_entity.dart';
import '../repositories/accounts_repository.dart';

class GetAccounts {
  const GetAccounts(this._repository);

  final AccountsRepository _repository;

  Future<List<AccountEntity>> call({
    bool includeArchived = false,
  }) {
    return _repository.getAccounts(
      includeArchived: includeArchived,
    );
  }
}
