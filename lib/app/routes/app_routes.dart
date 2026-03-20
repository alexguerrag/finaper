import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/sign_up_login_screen.dart';

class AppRoutes {
  static const String initial = '/';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SignUpLoginScreen(),
  };
}
