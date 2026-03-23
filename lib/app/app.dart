import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'routes/app_routes.dart';

class FinaperApp extends StatelessWidget {
  const FinaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finaper',
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'finaper_app',
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: AppRoutes.initial,
      routes: AppRoutes.routes,
    );
  }
}
