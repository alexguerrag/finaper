import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  try {
    await AppServices.instance.initialize();
  } catch (e, s) {
    debugPrint('Bootstrap error: $e');
    debugPrintStack(stackTrace: s);
  }

  runApp(const FinaperApp());
}
