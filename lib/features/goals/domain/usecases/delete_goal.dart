import '../repositories/goals_repository.dart';

class DeleteGoal {
  const DeleteGoal(this._repository);

  final GoalsRepository _repository;

  Future<void> call(String id) => _repository.deleteGoal(id);
}
