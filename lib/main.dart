import 'package:flutter/material.dart';

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
      home: Scaffold(body: Center(child: Text('Finaper App 🚀'))),
    );
  }
}
