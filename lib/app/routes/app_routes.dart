import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/sign_up_login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SignUpLoginScreen(),
    dashboard: (context) => const DashboardScreen(),
    transactions: (context) => const TransactionsScreen(),
  };
}
