import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../features/settings/di/settings_registry.dart';
import '../../features/settings/domain/entities/app_settings_entity.dart';

class AppFormatters {
  static const Map<String, String> _currencySymbols = {
    'CLP': r'$',
    'USD': r'US$',
    'EUR': '€',
    'ARS': r'AR$',
    'BRL': r'R$',
    'COP': r'COP$',
    'MXN': r'MX$',
    'PEN': 'S/',
  };

  static const Map<String, int> _currencyDecimalDigits = {
    'CLP': 0,
    'USD': 2,
    'EUR': 2,
    'ARS': 2,
    'BRL': 2,
    'COP': 0,
    'MXN': 2,
    'PEN': 2,
  };

  static const List<String> _spanishMonthNames = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static const List<String> _englishMonthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _portugueseMonthNames = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static AppSettingsEntity get _settings =>
      SettingsRegistry.module.controller.currentSettings;

  static String get _resolvedLocaleCode =>
      SettingsRegistry.module.controller.resolvedLocaleCode;

  static int get currentCurrencyDecimalDigits =>
      _currencyDecimalDigits[_settings.currencyCode] ?? 2;

  static String get currentCurrencyCode => _settings.currencyCode;

  static String formatCurrency(num value) {
    return formatCurrencyWith(
      value: value,
      currencyCode: _settings.currencyCode,
      localeCode: _resolvedLocaleCode,
    );
  }

  static String formatCurrencyWith({
    required num value,
    required String currencyCode,
    required String localeCode,
  }) {
    try {
      final normalizedLocale = _normalizeLocaleCode(localeCode);

      final formatter = NumberFormat.currency(
        locale: normalizedLocale,
        name: currencyCode,
        symbol: _currencySymbols[currencyCode] ?? '$currencyCode ',
        decimalDigits: _currencyDecimalDigits[currencyCode] ?? 2,
      );

      return formatter.format(value);
    } catch (e, s) {
      debugPrint('formatCurrencyWith error: $e');
      debugPrintStack(stackTrace: s);
      return value.toStringAsFixed(2);
    }
  }

  static String formatShortDate(DateTime value) {
    return formatShortDateWith(
      value: value,
      localeCode: _resolvedLocaleCode,
    );
  }

  static String formatShortDateWith({
    required DateTime value,
    required String localeCode,
  }) {
    try {
      return DateFormat.yMMMd(
        _normalizeLocaleCode(localeCode),
      ).format(value);
    } catch (e, s) {
      debugPrint('formatShortDateWith error: $e');
      debugPrintStack(stackTrace: s);
      return '${value.day}/${value.month}/${value.year}';
    }
  }

  static String formatMonthYear(DateTime value) {
    return formatMonthYearWith(
      value: value,
      localeCode: _resolvedLocaleCode,
    );
  }

  static String formatMonthYearWith({
    required DateTime value,
    required String localeCode,
  }) {
    final normalizedLocale = _normalizeLocaleCode(localeCode);

    try {
      return DateFormat.yMMMM(normalizedLocale).format(value);
    } catch (e, s) {
      if (_isLocaleDataNotInitializedError(e)) {
        return _fallbackMonthYear(
          value: value,
          localeCode: normalizedLocale,
        );
      }

      debugPrint('formatMonthYearWith error: $e');
      debugPrintStack(stackTrace: s);
      return _fallbackMonthYear(
        value: value,
        localeCode: normalizedLocale,
      );
    }
  }

  static bool _isLocaleDataNotInitializedError(Object error) {
    return error.toString().contains('Locale data has not been initialized');
  }

  static String _fallbackMonthYear({
    required DateTime value,
    required String localeCode,
  }) {
    final locale = localeCode.toLowerCase();

    if (locale.startsWith('es')) {
      return '${_spanishMonthNames[value.month - 1]} ${value.year}';
    }

    if (locale.startsWith('en')) {
      return '${_englishMonthNames[value.month - 1]} ${value.year}';
    }

    if (locale.startsWith('pt')) {
      return '${_portugueseMonthNames[value.month - 1]} de ${value.year}';
    }

    return '${value.month}/${value.year}';
  }

  static String _normalizeLocaleCode(String value) {
    final sanitized = value.trim().replaceAll('-', '_');

    if (sanitized.isEmpty) {
      return AppSettingsEntity.defaultLocaleCode;
    }

    final parts = sanitized.split('_');
    if (parts.length == 1) {
      return parts.first.toLowerCase();
    }

    return '${parts.first.toLowerCase()}_${parts.last.toUpperCase()}';
  }
}
