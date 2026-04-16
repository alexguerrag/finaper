import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budgets_repository.dart';
import '../local/budgets_local_datasource.dart';
import '../models/budget_model.dart';

class BudgetsRepositoryImpl implements BudgetsRepository {
  const BudgetsRepositoryImpl(this._localDataSource);

  final BudgetsLocalDataSource _localDataSource;

  @override
  Future<List<BudgetEntity>> getBudgetsByMonth({
    required String monthKey,
  }) {
    return _localDataSource.getBudgetsByMonth(
      monthKey: monthKey,
    );
  }

  @override
  Future<BudgetEntity> upsertBudget(BudgetEntity budget) {
    return _localDataSource.upsertBudget(
      BudgetModel.fromEntity(budget),
    );
  }

  @override
  Future<void> deleteBudget(String id) {
    return _localDataSource.deleteBudget(id);
  }
}
