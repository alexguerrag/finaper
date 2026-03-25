import '../../domain/entities/app_settings_entity.dart';

class AppSettingsModel extends AppSettingsEntity {
  const AppSettingsModel({
    required super.id,
    required super.currencyCode,
    required super.localeCode,
    required super.useSystemLocale,
    required super.updatedAt,
  });

  factory AppSettingsModel.defaults() {
    return AppSettingsModel.fromEntity(
      AppSettingsEntity.defaults(),
    );
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      id: map['id'] as int? ?? AppSettingsEntity.singletonId,
      currencyCode: map['currency_code']?.toString() ??
          AppSettingsEntity.defaultCurrencyCode,
      localeCode:
          map['locale_code']?.toString() ?? AppSettingsEntity.defaultLocaleCode,
      useSystemLocale: (map['use_system_locale'] as int? ?? 1) == 1,
      updatedAt: DateTime.tryParse(
            map['updated_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  factory AppSettingsModel.fromEntity(AppSettingsEntity entity) {
    return AppSettingsModel(
      id: entity.id,
      currencyCode: entity.currencyCode,
      localeCode: entity.localeCode,
      useSystemLocale: entity.useSystemLocale,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'currency_code': currencyCode,
      'locale_code': localeCode,
      'use_system_locale': useSystemLocale ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
