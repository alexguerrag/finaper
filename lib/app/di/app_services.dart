import 'package:flutter/foundation.dart';

import '../../core/database/database_helper.dart';
import '../../features/dashboard/data/local/dashboard_local_datasource.dart';
import '../../features/transactions/data/local/transaction_local_datasource.dart';
import '../../features/transactions/data/repositories/transactions_repository_impl.dart';
import '../../features/transactions/domain/repositories/transactions_repository.dart';
import '../../features/transactions/domain/usecases/add_transaction.dart';
import '../../features/transactions/domain/usecases/get_all_transactions.dart';

class AppServices {
  AppServices._();

  static final AppServices instance = AppServices._();

  final DatabaseHelper databaseHelper = DatabaseHelper.instance;

  late final TransactionLocalDataSource transactionLocalDataSource =
      TransactionLocalDataSourceImpl(databaseHelper);

  late final TransactionsRepository transactionsRepository =
      TransactionsRepositoryImpl(transactionLocalDataSource);

  late final GetAllTransactions getAllTransactions =
      GetAllTransactions(transactionsRepository);

  late final AddTransaction addTransaction =
      AddTransaction(transactionsRepository);

  late final DashboardLocalDataSource dashboardLocalDataSource =
      DashboardLocalDataSource(transactionLocalDataSource);

  Future<void> initialize() async {
    try {
      await databaseHelper.database;
    } catch (e, s) {
      debugPrint('AppServices.initialize error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
