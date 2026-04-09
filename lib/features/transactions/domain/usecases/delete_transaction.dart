import '../repositories/transactions_repository.dart';

class DeleteTransaction {
  const DeleteTransaction(this._repository);

  final TransactionsRepository _repository;

  Future<void> call(String id) {
    return _repository.delete(id);
  }
}
