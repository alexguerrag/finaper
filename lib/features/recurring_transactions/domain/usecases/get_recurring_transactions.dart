import '../entities/recurring_transaction_entity.dart';
import '../repositories/recurring_transactions_repository.dart';

class GetRecurringTransactions {
  const GetRecurringTransactions(this._repository);

  final RecurringTransactionsRepository _repository;

  Future<List<RecurringTransactionEntity>> call({
    bool includeInactive = true,
  }) {
    return _repository.getRecurringTransactions(
      includeInactive: includeInactive,
    );
  }
}
