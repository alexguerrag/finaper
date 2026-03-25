import '../../domain/entities/app_settings_entity.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../local/app_settings_local_datasource.dart';
import '../models/app_settings_model.dart';

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  const AppSettingsRepositoryImpl(this._localDataSource);

  final AppSettingsLocalDataSource _localDataSource;

  @override
  Future<AppSettingsEntity> getAppSettings() {
    return _localDataSource.getAppSettings();
  }

  @override
  Future<AppSettingsEntity> saveAppSettings(AppSettingsEntity settings) {
    return _localDataSource.saveAppSettings(
      AppSettingsModel.fromEntity(settings),
    );
  }
}
