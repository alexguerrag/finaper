import '../../../app/di/app_module.dart';
import '../../../core/database/database_helper.dart';
import '../data/local/recurring_transactions_local_datasource.dart';
import '../data/repositories/recurring_transactions_repository_impl.dart';
import '../domain/repositories/recurring_transactions_repository.dart';
import '../domain/usecases/create_recurring_transaction.dart';
import '../domain/usecases/delete_recurring_transaction.dart';
import '../domain/usecases/get_recurring_transactions.dart';
import '../domain/usecases/sync_due_recurring_transactions.dart';
import '../domain/usecases/update_recurring_transaction.dart';

class RecurringTransactionsModule implements AppModule {
  late final RecurringTransactionsLocalDataSource localDataSource;
  late final RecurringTransactionsRepository repository;
  late final GetRecurringTransactions getRecurringTransactions;
  late final CreateRecurringTransaction createRecurringTransaction;
  late final UpdateRecurringTransaction updateRecurringTransaction;
  late final DeleteRecurringTransaction deleteRecurringTransaction;
  late final SyncDueRecurringTransactions syncDueRecurringTransactions;

  final DatabaseHelper _databaseHelper;

  RecurringTransactionsModule({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<void> register() async {
    localDataSource = RecurringTransactionsLocalDataSourceImpl(_databaseHelper);
    repository = RecurringTransactionsRepositoryImpl(localDataSource);
    getRecurringTransactions = GetRecurringTransactions(repository);
    createRecurringTransaction = CreateRecurringTransaction(repository);
    updateRecurringTransaction = UpdateRecurringTransaction(repository);
    deleteRecurringTransaction = DeleteRecurringTransaction(repository);
    syncDueRecurringTransactions = SyncDueRecurringTransactions(repository);
  }
}
