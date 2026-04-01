import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../features/settings/di/settings_registry.dart';
import '../features/settings/presentation/controllers/settings_controller.dart';
import 'routes/app_routes.dart';

class FinaperApp extends StatelessWidget {
  const FinaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = SettingsRegistry.module.controller;

    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, child) {
        Intl.defaultLocale = settingsController.resolvedLocaleCode;

        return MaterialApp(
          title: 'Finaper',
          debugShowCheckedModeBanner: false,
          restorationScopeId: 'finaper_app',
          themeMode: ThemeMode.dark,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          locale: settingsController.materialAppLocale,
          supportedLocales: SettingsController.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: AppRoutes.initial,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
