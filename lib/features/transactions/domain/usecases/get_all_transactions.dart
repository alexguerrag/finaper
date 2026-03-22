import '../entities/transaction_entity.dart';
import '../repositories/transactions_repository.dart';

class GetAllTransactions {
  final TransactionsRepository repository;

  GetAllTransactions(this.repository);

  Future<List<TransactionEntity>> call() async {
    return repository.getAll();
  }
}
