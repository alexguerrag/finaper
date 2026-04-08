import 'package:finaper/features/recurring_transactions/di/recurring_transactions_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RecurringTransactionsModule registers dependencies', () async {
    final module = RecurringTransactionsModule();

    await module.register();

    expect(module.localDataSource, isNotNull);
    expect(module.repository, isNotNull);
    expect(module.getRecurringTransactions, isNotNull);
    expect(module.createRecurringTransaction, isNotNull);
    expect(module.updateRecurringTransaction, isNotNull);
    expect(module.syncDueRecurringTransactions, isNotNull);
  });
}
