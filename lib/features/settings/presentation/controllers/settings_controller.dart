import 'package:flutter/material.dart';

import '../../../../core/config/supported_locales.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/usecases/get_app_settings.dart';
import '../../domain/usecases/save_app_settings.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    required GetAppSettings getAppSettings,
    required SaveAppSettings saveAppSettings,
  })  : _getAppSettings = getAppSettings,
        _saveAppSettings = saveAppSettings;

  static const List<Locale> supportedLocales = AppSupportedLocales.all;

  /// Single source of truth for selectable currencies: (code, display label).
  static const List<(String, String)> supportedCurrencies = [
    ('CLP', '🇨🇱  Peso chileno (CLP)'),
    ('USD', '🇺🇸  Dólar estadounidense (USD)'),
    ('EUR', '🇪🇺  Euro (EUR)'),
    ('ARS', '🇦🇷  Peso argentino (ARS)'),
    ('BRL', '🇧🇷  Real brasileño (BRL)'),
    ('COP', '🇨🇴  Peso colombiano (COP)'),
    ('MXN', '🇲🇽  Peso mexicano (MXN)'),
    ('PEN', '🇵🇪  Sol peruano (PEN)'),
  ];

  static const List<(String, String)> supportedLocaleOptions =
      AppSupportedLocales.options;

  final GetAppSettings _getAppSettings;
  final SaveAppSettings _saveAppSettings;

  AppSettingsEntity _currentSettings = AppSettingsEntity.defaults();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  AppSettingsEntity get currentSettings => _currentSettings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Locale? get materialAppLocale {
    if (_currentSettings.useSystemLocale) {
      return null;
    }

    return _parseLocaleCode(_currentSettings.localeCode);
  }

  String get resolvedLocaleCode {
    if (_currentSettings.useSystemLocale) {
      return _platformLocaleCode();
    }

    return _normalizeLocaleCode(_currentSettings.localeCode);
  }

  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentSettings = await _getAppSettings();
      _errorMessage = null;
    } catch (e, s) {
      debugPrint('SettingsController.load error: $e');
      debugPrintStack(stackTrace: s);
      _errorMessage = 'No se pudieron cargar las preferencias.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get hasCompletedOnboarding => _currentSettings.hasCompletedOnboarding;

  Future<bool> saveGeneralSettings({
    required String currencyCode,
    required String localeCode,
    required bool useSystemLocale,
    bool? hasCompletedOnboarding,
  }) async {
    if (_isSaving) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final updated = _currentSettings.copyWith(
        currencyCode: currencyCode,
        localeCode: localeCode,
        useSystemLocale: useSystemLocale,
        hasCompletedOnboarding: hasCompletedOnboarding,
        updatedAt: DateTime.now(),
      );

      _currentSettings = await _saveAppSettings(updated);
      _errorMessage = null;
      return true;
    } catch (e, s) {
      debugPrint('SettingsController.saveGeneralSettings error: $e');
      debugPrintStack(stackTrace: s);
      _errorMessage = 'No se pudieron guardar las preferencias.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Locale _parseLocaleCode(String value) {
    final normalized = _normalizeLocaleCode(value);
    final parts = normalized.split('_');

    if (parts.length == 1) {
      return Locale.fromSubtags(languageCode: parts.first);
    }

    return Locale.fromSubtags(
      languageCode: parts.first,
      countryCode: parts.last,
    );
  }

  String _platformLocaleCode() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = locale.languageCode.trim();
    final countryCode = locale.countryCode?.trim();

    if (languageCode.isEmpty) {
      return AppSettingsEntity.defaultLocaleCode;
    }

    if (countryCode == null || countryCode.isEmpty) {
      return _normalizeLocaleCode(languageCode);
    }

    return _normalizeLocaleCode('${languageCode}_$countryCode');
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
