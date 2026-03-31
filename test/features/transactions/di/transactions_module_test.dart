import 'package:finaper/features/transactions/di/transactions_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TransactionsModule registers dependencies', () async {
    final module = TransactionsModule();

    await module.register();

    expect(module.localDataSource, isNotNull);
    expect(module.repository, isNotNull);
    expect(module.getAllTransactions, isNotNull);
    expect(module.addTransaction, isNotNull);
  });
}
