import 'package:finaper/app/di/app_locator.dart';
import 'package:finaper/features/accounts/di/accounts_module.dart';
import 'package:finaper/features/dashboard/di/dashboard_module.dart';
import 'package:finaper/features/transactions/di/transactions_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AppLocator.clear();
  });

  tearDown(() {
    AppLocator.clear();
  });

  test('DashboardModule registers dependencies', () async {
    final transactionsModule = TransactionsModule();
    await transactionsModule.register();
    AppLocator.register<TransactionsModule>(transactionsModule);

    final accountsModule = AccountsModule();
    await accountsModule.register();
    AppLocator.register<AccountsModule>(accountsModule);

    final dashboardModule = DashboardModule();
    await dashboardModule.register();
    AppLocator.register<DashboardModule>(dashboardModule);

    expect(dashboardModule.dashboardLocalDataSource, isNotNull);
  });
}
