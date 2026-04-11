import 'package:finaper/features/accounts/di/accounts_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AccountsModule registers dependencies', () async {
    final module = AccountsModule();

    await module.register();

    expect(module.localDataSource, isNotNull);
    expect(module.repository, isNotNull);
    expect(module.getAccounts, isNotNull);
    expect(module.getAccountBalances, isNotNull);
    expect(module.createAccount, isNotNull);
    expect(module.updateAccount, isNotNull);
  });
}
