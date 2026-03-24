import '../entities/budget_entity.dart';
import '../repositories/budgets_repository.dart';

class GetBudgetsByMonth {
  const GetBudgetsByMonth(this._repository);

  final BudgetsRepository _repository;

  Future<List<BudgetEntity>> call({
    required String monthKey,
  }) {
    return _repository.getBudgetsByMonth(
      monthKey: monthKey,
    );
  }
}
