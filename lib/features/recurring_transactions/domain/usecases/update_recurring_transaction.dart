import '../entities/recurring_transaction_entity.dart';
import '../repositories/recurring_transactions_repository.dart';

class UpdateRecurringTransaction {
  const UpdateRecurringTransaction(this._repository);

  final RecurringTransactionsRepository _repository;

  Future<RecurringTransactionEntity> call(
    RecurringTransactionEntity recurringTransaction,
  ) {
    return _repository.updateRecurringTransaction(recurringTransaction);
  }
}
