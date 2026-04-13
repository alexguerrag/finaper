import '../entities/account_transfer_entity.dart';
import '../repositories/transactions_repository.dart';

class UpdateAccountTransfer {
  const UpdateAccountTransfer(this._repository);

  final TransactionsRepository _repository;

  Future<void> call({
    required String transferGroupId,
    required AccountTransferEntity transfer,
  }) {
    return _repository.updateTransfer(
      transferGroupId: transferGroupId,
      transfer: transfer,
    );
  }
}
