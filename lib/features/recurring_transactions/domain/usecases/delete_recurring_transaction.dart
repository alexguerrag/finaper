import '../repositories/recurring_transactions_repository.dart';

class DeleteRecurringTransaction {
  const DeleteRecurringTransaction(this._repository);

  final RecurringTransactionsRepository _repository;

  Future<void> call(String id) => _repository.deleteRecurringTransaction(id);
}
