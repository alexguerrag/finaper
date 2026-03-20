import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1B9AAA),
        surface: Color(0xFF161B22),
      ),
    );
  }
}
