import '../entities/account_transfer_entity.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionsRepository {
  Future<List<TransactionEntity>> getAll();
  Future<TransactionEntity> add(TransactionEntity transaction);
  Future<TransactionEntity> update(TransactionEntity transaction);
  Future<void> delete(String id);
  Future<void> deleteByTransferGroup(String transferGroupId);
  Future<List<TransactionEntity>> createTransfer(
    AccountTransferEntity transfer,
  );
}
