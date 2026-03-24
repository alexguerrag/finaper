import '../entities/goal_entity.dart';
import '../repositories/goals_repository.dart';

class UpdateGoal {
  const UpdateGoal(this._repository);

  final GoalsRepository _repository;

  Future<GoalEntity> call(GoalEntity goal) {
    return _repository.updateGoal(goal);
  }
}
