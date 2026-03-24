import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finaper/features/goals/domain/entities/goal_entity.dart';

void main() {
  test('GoalEntity progress y remainingAmount calculan correctamente', () {
    final goal = GoalEntity(
      id: 'goal-1',
      name: 'Fondo de emergencia',
      targetAmount: 1000,
      currentAmount: 250,
      targetDate: null,
      color: Colors.blue,
      iconCode: Icons.savings_rounded.codePoint,
      isCompleted: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    expect(goal.progress, 0.25);
    expect(goal.remainingAmount, 750);
  });
}
