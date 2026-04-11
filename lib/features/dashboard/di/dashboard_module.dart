import '../../../app/di/app_module.dart';
import '../../accounts/di/accounts_registry.dart';
import '../../transactions/di/transactions_registry.dart';
import '../data/local/dashboard_local_datasource.dart';

class DashboardModule implements AppModule {
  late final DashboardLocalDataSource dashboardLocalDataSource;

  @override
  Future<void> register() async {
    dashboardLocalDataSource = DashboardLocalDataSource(
      TransactionsRegistry.module.localDataSource,
      AccountsRegistry.module.localDataSource,
    );
  }
}
