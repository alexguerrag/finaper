import 'package:flutter/material.dart';

import 'app/bootstrap/app_bootstrap_entry.dart';
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
      home: const AppBootstrapEntry(),
    ),
  );
}
