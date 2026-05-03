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

  /// Display labels for each locale — order matches [all].
  static const List<(String, String)> options = [
    ('es_CL', 'Español (Chile)'),
    ('es_ES', 'Español (España)'),
    ('es_AR', 'Español (Argentina)'),
    ('es_MX', 'Español (México)'),
    ('es_CO', 'Español (Colombia)'),
    ('es_PE', 'Español (Perú)'),
    ('en_US', 'English (United States)'),
    ('pt_BR', 'Português (Brasil)'),
  ];
}
