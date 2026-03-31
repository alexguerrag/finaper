import '../../../app/di/app_module.dart';
import '../../../core/database/database_helper.dart';
import '../data/local/app_settings_local_datasource.dart';
import '../data/repositories/app_settings_repository_impl.dart';
import '../domain/repositories/app_settings_repository.dart';
import '../domain/usecases/get_app_settings.dart';
import '../domain/usecases/save_app_settings.dart';
import '../presentation/controllers/settings_controller.dart';

class SettingsModule implements AppModule {
  SettingsModule({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  late final AppSettingsLocalDataSource appSettingsLocalDataSource =
      AppSettingsLocalDataSourceImpl(_databaseHelper);

  late final AppSettingsRepository appSettingsRepository =
      AppSettingsRepositoryImpl(appSettingsLocalDataSource);

  late final GetAppSettings getAppSettings =
      GetAppSettings(appSettingsRepository);

  late final SaveAppSettings saveAppSettings =
      SaveAppSettings(appSettingsRepository);

  late final SettingsController settingsController = SettingsController(
    getAppSettings: getAppSettings,
    saveAppSettings: saveAppSettings,
  );

  @override
  Future<void> register() async {
    // Módulo preparado para composición incremental.
  }
}
