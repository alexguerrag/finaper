import '../repositories/budgets_repository.dart';

class DeleteBudget {
  const DeleteBudget(this._repository);

  final BudgetsRepository _repository;

  Future<void> call(String id) => _repository.deleteBudget(id);
}
