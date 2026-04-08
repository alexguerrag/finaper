import '../../../app/di/app_module.dart';
import '../../../core/database/database_helper.dart';
import '../../transactions/data/local/transaction_local_datasource.dart';
import '../data/local/dashboard_local_datasource.dart';

class DashboardModule implements AppModule {
  late final TransactionLocalDataSource transactionLocalDataSource;
  late final DashboardLocalDataSource dashboardLocalDataSource;

  final DatabaseHelper _databaseHelper;

  DashboardModule({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<void> register() async {
    transactionLocalDataSource =
        TransactionLocalDataSourceImpl(_databaseHelper);
    dashboardLocalDataSource =
        DashboardLocalDataSource(transactionLocalDataSource);
  }
}
