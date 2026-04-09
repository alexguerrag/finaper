import '../../../app/di/app_module.dart';
import '../../../core/database/database_helper.dart';
import '../data/local/transaction_form_preferences_local_datasource.dart';
import '../data/local/transaction_local_datasource.dart';
import '../data/repositories/transaction_form_preferences_repository_impl.dart';
import '../data/repositories/transactions_repository_impl.dart';
import '../domain/repositories/transaction_form_preferences_repository.dart';
import '../domain/repositories/transactions_repository.dart';
import '../domain/usecases/add_transaction.dart';
import '../domain/usecases/delete_transaction.dart';
import '../domain/usecases/get_all_transactions.dart';
import '../domain/usecases/get_transaction_form_preferences.dart';
import '../domain/usecases/save_transaction_form_preferences.dart';
import '../domain/usecases/update_transaction.dart';

class TransactionsModule implements AppModule {
  late final TransactionLocalDataSource localDataSource;
  late final TransactionsRepository repository;
  late final GetAllTransactions getAllTransactions;
  late final AddTransaction addTransaction;
  late final UpdateTransaction updateTransaction;
  late final DeleteTransaction deleteTransaction;

  late final TransactionFormPreferencesLocalDataSource
      preferencesLocalDataSource;
  late final TransactionFormPreferencesRepository preferencesRepository;
  late final GetTransactionFormPreferences getTransactionFormPreferences;
  late final SaveTransactionFormPreferences saveTransactionFormPreferences;

  final DatabaseHelper _databaseHelper;

  TransactionsModule({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<void> register() async {
    localDataSource = TransactionLocalDataSourceImpl(_databaseHelper);
    repository = TransactionsRepositoryImpl(localDataSource);
    getAllTransactions = GetAllTransactions(repository);
    addTransaction = AddTransaction(repository);
    updateTransaction = UpdateTransaction(repository);
    deleteTransaction = DeleteTransaction(repository);

    preferencesLocalDataSource =
        TransactionFormPreferencesLocalDataSourceImpl(_databaseHelper);
    preferencesRepository = TransactionFormPreferencesRepositoryImpl(
      preferencesLocalDataSource,
    );
    getTransactionFormPreferences = GetTransactionFormPreferences(
      preferencesRepository,
    );
    saveTransactionFormPreferences = SaveTransactionFormPreferences(
      preferencesRepository,
    );
  }
}
