import '../entities/transaction_entity.dart';
import '../repositories/transactions_repository.dart';

class AddTransaction {
  final TransactionsRepository repository;

  AddTransaction(this.repository);

  Future<TransactionEntity> call(TransactionEntity transaction) async {
    return repository.add(transaction);
  }
}
