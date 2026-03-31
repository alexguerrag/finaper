import 'package:finaper/features/budgets/domain/utils/budget_month_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('budgetMonthKeyFromDate retorna YYYY-MM', () {
    final result = budgetMonthKeyFromDate(DateTime(2026, 3, 23));

    expect(result, '2026-03');
  });
}
