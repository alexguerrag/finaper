import '../entities/app_settings_entity.dart';

abstract class AppSettingsRepository {
  Future<AppSettingsEntity> getAppSettings();

  Future<AppSettingsEntity> saveAppSettings(AppSettingsEntity settings);
}
