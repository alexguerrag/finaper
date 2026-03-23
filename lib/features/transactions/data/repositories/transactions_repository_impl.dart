import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../models/transaction_model.dart';
import '../local/transaction_local_datasource.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  final TransactionLocalDataSource localDataSource;

  TransactionsRepositoryImpl(this.localDataSource);

  @override
  Future<List<TransactionEntity>> getAll() async {
    final models = await localDataSource.getTransactions();
    // Mapeo explícito de Model (Data) a Entity (Domain)
    return models.map((model) => model as TransactionEntity).toList();
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
  // Cambiado de int a String para coincidir con nuestro modelo de datos
  Future<void> delete(String id) async {
    await localDataSource.deleteTransaction(id);
  }
}
