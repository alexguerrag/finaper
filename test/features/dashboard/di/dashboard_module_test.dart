import 'package:finaper/features/dashboard/di/dashboard_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DashboardModule registers dependencies', () async {
    final module = DashboardModule();

    await module.register();

    expect(module.transactionLocalDataSource, isNotNull);
    expect(module.dashboardLocalDataSource, isNotNull);
  });
}
