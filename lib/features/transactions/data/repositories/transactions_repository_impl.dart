import '../../domain/entities/account_transfer_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../local/transaction_local_datasource.dart';
import '../models/transaction_model.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  final TransactionLocalDataSource localDataSource;

  TransactionsRepositoryImpl(this.localDataSource);

  @override
  Future<List<TransactionEntity>> getAll() async {
    final models = await localDataSource.getTransactions();
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
  Future<void> delete(String id) async {
    await localDataSource.deleteTransaction(id);
  }

  @override
  Future<List<TransactionEntity>> createTransfer(
    AccountTransferEntity transfer,
  ) async {
    final models = await localDataSource.createTransfer(transfer);
    return models.map((model) => model as TransactionEntity).toList();
  }
}
