import '../../../app/di/app_module.dart';
import '../../../core/database/database_helper.dart';
import '../data/local/transaction_local_datasource.dart';
import '../data/repositories/transactions_repository_impl.dart';
import '../domain/repositories/transactions_repository.dart';
import '../domain/usecases/add_transaction.dart';
import '../domain/usecases/get_all_transactions.dart';

class TransactionsModule implements AppModule {
  late final TransactionLocalDataSource localDataSource;
  late final TransactionsRepository repository;
  late final GetAllTransactions getAllTransactions;
  late final AddTransaction addTransaction;

  final DatabaseHelper _databaseHelper;

  TransactionsModule({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<void> register() async {
    localDataSource = TransactionLocalDataSourceImpl(_databaseHelper);
    repository = TransactionsRepositoryImpl(localDataSource);
    getAllTransactions = GetAllTransactions(repository);
    addTransaction = AddTransaction(repository);
  }
}
