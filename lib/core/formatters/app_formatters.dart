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
  };

  static const Map<String, int> _currencyDecimalDigits = {
    'CLP': 0,
    'USD': 2,
    'EUR': 2,
    'ARS': 2,
    'BRL': 2,
    'COP': 0,
    'MXN': 2,
  };

  static AppSettingsEntity get _settings =>
      SettingsRegistry.module.controller.currentSettings;

  static String get _resolvedLocaleCode =>
      SettingsRegistry.module.controller.resolvedLocaleCode;

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
    try {
      return DateFormat.yMMMM(_resolvedLocaleCode).format(value);
    } catch (e, s) {
      debugPrint('formatMonthYear error: $e');
      debugPrintStack(stackTrace: s);
      return '${value.month}/${value.year}';
    }
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
