// C:\dev\projects\finaper\lib\main.dart
import 'package:flutter/material.dart';
import 'package:finaper/features/shell/presentation/pages/main_shell_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinaperApp());
}

class FinaperApp extends StatelessWidget {
  const FinaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finaper',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MainShellPage(),
    );
  }
}
