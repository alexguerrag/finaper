import '../entities/transaction_entity.dart';

abstract class TransactionsRepository {
  Future<List<TransactionEntity>> getAll();
  Future<TransactionEntity> add(TransactionEntity transaction);
  Future<TransactionEntity> update(TransactionEntity transaction);
  Future<void> delete(int id);
}
