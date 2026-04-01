import '../../../app/di/app_module.dart';
import '../../../core/database/database_helper.dart';
import '../data/local/budgets_local_datasource.dart';
import '../data/repositories/budgets_repository_impl.dart';
import '../domain/repositories/budgets_repository.dart';
import '../domain/usecases/get_budgets_by_month.dart';
import '../domain/usecases/upsert_budget.dart';

class BudgetsModule implements AppModule {
  late final BudgetsLocalDataSource localDataSource;
  late final BudgetsRepository repository;
  late final GetBudgetsByMonth getBudgetsByMonth;
  late final UpsertBudget upsertBudget;

  final DatabaseHelper _databaseHelper;

  BudgetsModule({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<void> register() async {
    localDataSource = BudgetsLocalDataSourceImpl(_databaseHelper);
    repository = BudgetsRepositoryImpl(localDataSource);
    getBudgetsByMonth = GetBudgetsByMonth(repository);
    upsertBudget = UpsertBudget(repository);
  }
}
