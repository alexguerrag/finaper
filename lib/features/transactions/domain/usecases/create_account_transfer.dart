import '../entities/account_transfer_entity.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transactions_repository.dart';

class CreateAccountTransfer {
  const CreateAccountTransfer(this._repository);

  final TransactionsRepository _repository;

  Future<List<TransactionEntity>> call(AccountTransferEntity transfer) {
    return _repository.createTransfer(transfer);
  }
}
