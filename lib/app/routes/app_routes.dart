import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/sign_up_login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SignUpLoginScreen(),
    dashboard: (context) => const DashboardScreen(),
  };
}
