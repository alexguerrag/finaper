import '../entities/goal_entity.dart';
import '../repositories/goals_repository.dart';

class GetGoals {
  const GetGoals(this._repository);

  final GoalsRepository _repository;

  Future<List<GoalEntity>> call({
    bool includeCompleted = true,
  }) {
    return _repository.getGoals(
      includeCompleted: includeCompleted,
    );
  }
}
