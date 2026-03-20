import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const FinaperApp());
}

class FinaperApp extends StatelessWidget {
  const FinaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finaper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const Scaffold(body: Center(child: Text('Finaper App 🚀'))),
    );
  }
}
