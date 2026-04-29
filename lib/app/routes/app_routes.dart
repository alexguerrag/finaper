import 'package:flutter/material.dart';

import '../../features/accounts/presentation/screens/accounts_screen.dart';
import '../../features/analytics/presentation/screens/premium_reports_screen.dart';
import '../../features/budgets/presentation/screens/budgets_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/export_backup/presentation/screens/backup_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/recurring_transactions/presentation/screens/recurring_transactions_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/pages/main_shell_page.dart';
import '../../features/transactions/presentation/screens/account_transfer_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String shell = '/shell';
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String accountTransfer = '/account-transfer';
  static const String accounts = '/accounts';
  static const String categories = '/categories';
  static const String budgets = '/budgets';
  static const String goals = '/goals';
  static const String recurringTransactions = '/recurring-transactions';
  static const String settings = '/settings';
  static const String backup = '/backup';
  static const String premiumReports = '/premium-reports';

  static Map<String, WidgetBuilder> get routes => {
        initial: (_) => const OnboardingScreen(),
        shell: (_) => const MainShellPage(),
        dashboard: (_) => const DashboardScreen(),
        transactions: (_) => const TransactionsScreen(),
        accountTransfer: (_) => const AccountTransferScreen(),
        accounts: (_) => const AccountsScreen(),
        categories: (_) => const CategoriesScreen(),
        budgets: (_) => const BudgetsScreen(),
        goals: (_) => const GoalsScreen(),
        recurringTransactions: (_) => const RecurringTransactionsScreen(),
        settings: (_) => const SettingsScreen(),
        backup: (_) => const BackupScreen(),
        premiumReports: (_) => const PremiumReportsScreen(),
      };
}
