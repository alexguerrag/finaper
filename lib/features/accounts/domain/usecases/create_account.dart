import '../entities/account_entity.dart';
import '../repositories/accounts_repository.dart';

class CreateAccount {
  const CreateAccount(this._repository);

  final AccountsRepository _repository;

  Future<AccountEntity> call(AccountEntity account) {
    return _repository.createAccount(account);
  }
}
