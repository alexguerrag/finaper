// C:\dev\projects\finaper\lib\features\transactions\data\repositories\transactions_repository_impl.dart
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../models/transaction_model.dart';
import '../local/transaction_local_datasource.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  final TransactionLocalDataSource localDataSource;

  TransactionsRepositoryImpl(this.localDataSource);

  @override
  Future<List<TransactionEntity>> getAll() async {
    final result = await localDataSource.getTransactions();
    return List<TransactionEntity>.from(result);
  }

  @override
  Future<TransactionEntity> add(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    return await localDataSource.insertTransaction(model);
  }

  @override
  Future<TransactionEntity> update(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    return await localDataSource.updateTransaction(model);
  }

  @override
  Future<void> delete(int id) async {
    await localDataSource.deleteTransaction(id);
  }
}
