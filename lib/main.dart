import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/bootstrap/app_bootstrap_entry.dart';
import 'core/config/supported_locales.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      // Bootstrap locale until SettingsController loads and app.dart overrides it.
      locale: const Locale('es', 'CL'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: AppSupportedLocales.all,
      home: const AppBootstrapEntry(),
    ),
  );
}
