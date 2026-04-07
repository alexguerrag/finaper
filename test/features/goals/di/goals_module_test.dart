import 'package:finaper/features/goals/di/goals_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GoalsModule registers dependencies', () async {
    final module = GoalsModule();

    await module.register();

    expect(module.localDataSource, isNotNull);
    expect(module.repository, isNotNull);
    expect(module.getGoals, isNotNull);
    expect(module.createGoal, isNotNull);
    expect(module.updateGoal, isNotNull);
  });
}
