import '../repositories/transactions_repository.dart';

class DeleteTransactionGroup {
  const DeleteTransactionGroup(this._repository);

  final TransactionsRepository _repository;

  Future<void> call(String transferGroupId) {
    return _repository.deleteByTransferGroup(transferGroupId);
  }
}
