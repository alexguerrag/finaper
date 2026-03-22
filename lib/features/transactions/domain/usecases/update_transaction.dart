import '../entities/transaction_entity.dart';
import '../repositories/transactions_repository.dart';

class UpdateTransaction {
  final TransactionsRepository repository;

  UpdateTransaction(this.repository);

  Future<TransactionEntity> call(TransactionEntity transaction) async {
    return repository.update(transaction);
  }
}
