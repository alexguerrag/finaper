import '../entities/transaction_entity.dart';
import '../repositories/transactions_repository.dart';

class UpdateTransaction {
  const UpdateTransaction(this._repository);

  final TransactionsRepository _repository;

  Future<TransactionEntity> call(TransactionEntity transaction) {
    return _repository.update(transaction);
  }
}
