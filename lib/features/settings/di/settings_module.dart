import '../../../app/di/app_module.dart';
import '../../../core/database/database_helper.dart';
import '../data/local/app_settings_local_datasource.dart';
import '../data/repositories/app_settings_repository_impl.dart';
import '../domain/repositories/app_settings_repository.dart';
import '../domain/usecases/get_app_settings.dart';
import '../domain/usecases/save_app_settings.dart';
import '../presentation/controllers/settings_controller.dart';

class SettingsModule implements AppModule {
  late final AppSettingsLocalDataSource localDataSource;
  late final AppSettingsRepository repository;
  late final GetAppSettings getAppSettings;
  late final SaveAppSettings saveAppSettings;
  late final SettingsController controller;

  final DatabaseHelper _databaseHelper;

  SettingsModule({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<void> register() async {
    localDataSource = AppSettingsLocalDataSourceImpl(_databaseHelper);
    repository = AppSettingsRepositoryImpl(localDataSource);
    getAppSettings = GetAppSettings(repository);
    saveAppSettings = SaveAppSettings(repository);
    controller = SettingsController(
      getAppSettings: getAppSettings,
      saveAppSettings: saveAppSettings,
    );
  }
}
