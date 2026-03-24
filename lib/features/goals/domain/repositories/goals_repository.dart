import '../entities/goal_entity.dart';

abstract class GoalsRepository {
  Future<List<GoalEntity>> getGoals({
    bool includeCompleted = true,
  });

  Future<GoalEntity> createGoal(GoalEntity goal);

  Future<GoalEntity> updateGoal(GoalEntity goal);
}
