import '../entities/app_settings_entity.dart';
import '../repositories/app_settings_repository.dart';

class SaveAppSettings {
  const SaveAppSettings(this._repository);

  final AppSettingsRepository _repository;

  Future<AppSettingsEntity> call(AppSettingsEntity settings) {
    return _repository.saveAppSettings(settings);
  }
}
