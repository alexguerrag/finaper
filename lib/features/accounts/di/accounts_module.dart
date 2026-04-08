import '../../../app/di/app_module.dart';
import '../../../core/database/database_helper.dart';
import '../data/local/accounts_local_datasource.dart';
import '../data/repositories/accounts_repository_impl.dart';
import '../domain/repositories/accounts_repository.dart';
import '../domain/usecases/create_account.dart';
import '../domain/usecases/get_accounts.dart';

class AccountsModule implements AppModule {
  late final AccountsLocalDataSource localDataSource;
  late final AccountsRepository repository;
  late final GetAccounts getAccounts;
  late final CreateAccount createAccount;

  final DatabaseHelper _databaseHelper;

  AccountsModule({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<void> register() async {
    localDataSource = AccountsLocalDataSourceImpl(_databaseHelper);
    repository = AccountsRepositoryImpl(localDataSource);
    getAccounts = GetAccounts(repository);
    createAccount = CreateAccount(repository);
  }
}
