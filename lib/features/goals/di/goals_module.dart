import '../../../app/di/app_module.dart';
import '../../../core/database/database_helper.dart';
import '../data/local/goals_local_datasource.dart';
import '../data/repositories/goals_repository_impl.dart';
import '../domain/repositories/goals_repository.dart';
import '../domain/usecases/create_goal.dart';
import '../domain/usecases/get_goals.dart';
import '../domain/usecases/update_goal.dart';

class GoalsModule implements AppModule {
  late final GoalsLocalDataSource localDataSource;
  late final GoalsRepository repository;
  late final GetGoals getGoals;
  late final CreateGoal createGoal;
  late final UpdateGoal updateGoal;

  final DatabaseHelper _databaseHelper;

  GoalsModule({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<void> register() async {
    localDataSource = GoalsLocalDataSourceImpl(_databaseHelper);
    repository = GoalsRepositoryImpl(localDataSource);
    getGoals = GetGoals(repository);
    createGoal = CreateGoal(repository);
    updateGoal = UpdateGoal(repository);
  }
}
