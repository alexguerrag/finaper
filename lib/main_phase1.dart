import 'package:flutter/material.dart';

import 'app/bootstrap/app_bootstrap_entry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrapEntry());
}
