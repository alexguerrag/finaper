import 'package:finaper/features/budgets/di/budgets_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BudgetsModule registers dependencies', () async {
    final module = BudgetsModule();

    await module.register();

    expect(module.localDataSource, isNotNull);
    expect(module.repository, isNotNull);
    expect(module.getBudgetsByMonth, isNotNull);
    expect(module.upsertBudget, isNotNull);
  });
}
