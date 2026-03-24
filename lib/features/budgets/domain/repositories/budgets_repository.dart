import '../entities/budget_entity.dart';

abstract class BudgetsRepository {
  Future<List<BudgetEntity>> getBudgetsByMonth({
    required String monthKey,
  });

  Future<BudgetEntity> upsertBudget(BudgetEntity budget);
}
