import '../repositories/recurring_transactions_repository.dart';

class SyncDueRecurringTransactions {
  const SyncDueRecurringTransactions(this._repository);

  final RecurringTransactionsRepository _repository;

  Future<int> call() {
    return _repository.syncDueRecurringTransactions();
  }
}
