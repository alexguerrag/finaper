import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/repositories/recurring_transactions_repository.dart';
import '../local/recurring_transactions_local_datasource.dart';
import '../models/recurring_transaction_model.dart';

class RecurringTransactionsRepositoryImpl
    implements RecurringTransactionsRepository {
  const RecurringTransactionsRepositoryImpl(this._localDataSource);

  final RecurringTransactionsLocalDataSource _localDataSource;

  @override
  Future<List<RecurringTransactionEntity>> getRecurringTransactions({
    bool includeInactive = true,
  }) {
    return _localDataSource.getRecurringTransactions(
      includeInactive: includeInactive,
    );
  }

  @override
  Future<RecurringTransactionEntity> createRecurringTransaction(
    RecurringTransactionEntity recurringTransaction,
  ) {
    return _localDataSource.createRecurringTransaction(
      RecurringTransactionModel.fromEntity(recurringTransaction),
    );
  }

  @override
  Future<RecurringTransactionEntity> updateRecurringTransaction(
    RecurringTransactionEntity recurringTransaction,
  ) {
    return _localDataSource.updateRecurringTransaction(
      RecurringTransactionModel.fromEntity(recurringTransaction),
    );
  }

  @override
  Future<int> syncDueRecurringTransactions() {
    return _localDataSource.syncDueRecurringTransactions();
  }
}
