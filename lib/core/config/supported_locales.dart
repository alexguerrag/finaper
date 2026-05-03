import 'package:flutter/material.dart';

/// Single source of truth for all locales Finaper supports.
///
/// Import this constant in main.dart and SettingsController — never
/// define the locale list in more than one place.
class AppSupportedLocales {
  const AppSupportedLocales._();

  static const List<Locale> all = [
    Locale('es', 'CL'),
    Locale('es', 'ES'),
    Locale('es', 'AR'),
    Locale('es', 'MX'),
    Locale('es', 'CO'),
    Locale('es', 'PE'),
    Locale('en', 'US'),
    Locale('pt', 'BR'),
  ];
}
