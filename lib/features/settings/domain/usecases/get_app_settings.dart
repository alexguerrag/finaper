import '../entities/app_settings_entity.dart';
import '../repositories/app_settings_repository.dart';

class GetAppSettings {
  const GetAppSettings(this._repository);

  final AppSettingsRepository _repository;

  Future<AppSettingsEntity> call() {
    return _repository.getAppSettings();
  }
}
