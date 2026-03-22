import '../repositories/transactions_repository.dart';

class DeleteTransaction {
  final TransactionsRepository repository;

  DeleteTransaction(this.repository);

  Future<void> call(int id) async {
    return repository.delete(id);
  }
}
