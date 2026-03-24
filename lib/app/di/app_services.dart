import 'package:flutter/foundation.dart';

import '../../core/database/database_helper.dart';
import '../../features/accounts/data/local/accounts_local_datasource.dart';
import '../../features/accounts/data/repositories/accounts_repository_impl.dart';
import '../../features/accounts/domain/repositories/accounts_repository.dart';
import '../../features/accounts/domain/usecases/create_account.dart';
import '../../features/accounts/domain/usecases/get_accounts.dart';
import '../../features/budgets/data/local/budgets_local_datasource.dart';
import '../../features/budgets/data/repositories/budgets_repository_impl.dart';
import '../../features/budgets/domain/repositories/budgets_repository.dart';
import '../../features/budgets/domain/usecases/get_budgets_by_month.dart';
import '../../features/budgets/domain/usecases/upsert_budget.dart';
import '../../features/categories/data/local/categories_local_datasource.dart';
import '../../features/categories/data/repositories/categories_repository_impl.dart';
import '../../features/categories/domain/repositories/categories_repository.dart';
import '../../features/categories/domain/usecases/create_category.dart';
import '../../features/categories/domain/usecases/get_categories_by_kind.dart';
import '../../features/dashboard/data/local/dashboard_local_datasource.dart';
import '../../features/goals/data/local/goals_local_datasource.dart';
import '../../features/goals/data/repositories/goals_repository_impl.dart';
import '../../features/goals/domain/repositories/goals_repository.dart';
import '../../features/goals/domain/usecases/create_goal.dart';
import '../../features/goals/domain/usecases/get_goals.dart';
import '../../features/goals/domain/usecases/update_goal.dart';
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

  late final AccountsLocalDataSource accountsLocalDataSource =
      AccountsLocalDataSourceImpl(databaseHelper);

  late final AccountsRepository accountsRepository =
      AccountsRepositoryImpl(accountsLocalDataSource);

  late final GetAccounts getAccounts = GetAccounts(accountsRepository);

  late final CreateAccount createAccount = CreateAccount(accountsRepository);

  late final CategoriesLocalDataSource categoriesLocalDataSource =
      CategoriesLocalDataSourceImpl(databaseHelper);

  late final CategoriesRepository categoriesRepository =
      CategoriesRepositoryImpl(categoriesLocalDataSource);

  late final GetCategoriesByKind getCategoriesByKind =
      GetCategoriesByKind(categoriesRepository);

  late final CreateCategory createCategory =
      CreateCategory(categoriesRepository);

  late final BudgetsLocalDataSource budgetsLocalDataSource =
      BudgetsLocalDataSourceImpl(databaseHelper);

  late final BudgetsRepository budgetsRepository =
      BudgetsRepositoryImpl(budgetsLocalDataSource);

  late final GetBudgetsByMonth getBudgetsByMonth =
      GetBudgetsByMonth(budgetsRepository);

  late final UpsertBudget upsertBudget = UpsertBudget(budgetsRepository);

  late final GoalsLocalDataSource goalsLocalDataSource =
      GoalsLocalDataSourceImpl(databaseHelper);

  late final GoalsRepository goalsRepository =
      GoalsRepositoryImpl(goalsLocalDataSource);

  late final GetGoals getGoals = GetGoals(goalsRepository);

  late final CreateGoal createGoal = CreateGoal(goalsRepository);

  late final UpdateGoal updateGoal = UpdateGoal(goalsRepository);

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
