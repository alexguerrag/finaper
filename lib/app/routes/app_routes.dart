import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/sign_up_login_screen.dart';
import '../../features/budgets/presentation/screens/budgets_screen.dart';
import '../../features/catalogs/presentation/screens/catalogs_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/shell/presentation/pages/main_shell_page.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String shell = '/shell';
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String catalogs = '/catalogs';
  static const String budgets = '/budgets';

  static Map<String, WidgetBuilder> get routes => {
        initial: (_) => const SignUpLoginScreen(),
        shell: (_) => const MainShellPage(),
        dashboard: (_) => const DashboardScreen(),
        transactions: (_) => const TransactionsScreen(),
        catalogs: (_) => const CatalogsScreen(),
        budgets: (_) => const BudgetsScreen(),
      };
}
