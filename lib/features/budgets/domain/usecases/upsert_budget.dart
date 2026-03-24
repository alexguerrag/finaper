import '../entities/budget_entity.dart';
import '../repositories/budgets_repository.dart';

class UpsertBudget {
  const UpsertBudget(this._repository);

  final BudgetsRepository _repository;

  Future<BudgetEntity> call(BudgetEntity budget) {
    return _repository.upsertBudget(budget);
  }
}
