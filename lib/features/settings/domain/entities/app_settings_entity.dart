import 'package:equatable/equatable.dart';

class AppSettingsEntity extends Equatable {
  const AppSettingsEntity({
    required this.id,
    required this.currencyCode,
    required this.localeCode,
    required this.useSystemLocale,
    required this.updatedAt,
  });

  static const int singletonId = 1;
  static const String defaultCurrencyCode = 'CLP';
  static const String defaultLocaleCode = 'es_CL';

  final int id;
  final String currencyCode;
  final String localeCode;
  final bool useSystemLocale;
  final DateTime updatedAt;

  factory AppSettingsEntity.defaults() {
    return AppSettingsEntity(
      id: singletonId,
      currencyCode: defaultCurrencyCode,
      localeCode: defaultLocaleCode,
      useSystemLocale: true,
      updatedAt: DateTime.now(),
    );
  }

  AppSettingsEntity copyWith({
    int? id,
    String? currencyCode,
    String? localeCode,
    bool? useSystemLocale,
    DateTime? updatedAt,
  }) {
    return AppSettingsEntity(
      id: id ?? this.id,
      currencyCode: currencyCode ?? this.currencyCode,
      localeCode: localeCode ?? this.localeCode,
      useSystemLocale: useSystemLocale ?? this.useSystemLocale,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        currencyCode,
        localeCode,
        useSystemLocale,
        updatedAt,
      ];
}
