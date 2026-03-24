import '../../domain/entities/goal_entity.dart';
import '../../domain/repositories/goals_repository.dart';
import '../local/goals_local_datasource.dart';
import '../models/goal_model.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  const GoalsRepositoryImpl(this._localDataSource);

  final GoalsLocalDataSource _localDataSource;

  @override
  Future<List<GoalEntity>> getGoals({
    bool includeCompleted = true,
  }) {
    return _localDataSource.getGoals(
      includeCompleted: includeCompleted,
    );
  }

  @override
  Future<GoalEntity> createGoal(GoalEntity goal) {
    return _localDataSource.createGoal(
      GoalModel.fromEntity(goal),
    );
  }

  @override
  Future<GoalEntity> updateGoal(GoalEntity goal) {
    return _localDataSource.updateGoal(
      GoalModel.fromEntity(goal),
    );
  }
}
