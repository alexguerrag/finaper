import '../entities/recurring_transaction_entity.dart';

abstract class RecurringTransactionsRepository {
  Future<List<RecurringTransactionEntity>> getRecurringTransactions({
    bool includeInactive = true,
  });

  Future<RecurringTransactionEntity> createRecurringTransaction(
    RecurringTransactionEntity recurringTransaction,
  );

  Future<RecurringTransactionEntity> updateRecurringTransaction(
    RecurringTransactionEntity recurringTransaction,
  );

  Future<int> syncDueRecurringTransactions();
}
