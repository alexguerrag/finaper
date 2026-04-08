import '../../../app/di/app_module.dart';
import '../../../core/database/database_helper.dart';
import '../data/local/export_backup_local_datasource.dart';
import '../data/local/export_file_actions_local_datasource.dart';
import '../data/repositories/export_backup_repository_impl.dart';
import '../data/repositories/export_file_actions_repository_impl.dart';
import '../domain/repositories/export_backup_repository.dart';
import '../domain/repositories/export_file_actions_repository.dart';
import '../domain/usecases/copy_export_file_path.dart';
import '../domain/usecases/export_backup_json.dart';
import '../domain/usecases/export_transactions_csv.dart';
import '../domain/usecases/open_export_file.dart';
import '../domain/usecases/share_export_file.dart';
import '../presentation/controllers/export_file_actions_controller.dart';

class ExportModule implements AppModule {
  late final ExportBackupLocalDataSource exportBackupLocalDataSource;
  late final ExportBackupRepository exportBackupRepository;
  late final ExportBackupJson exportBackupJson;
  late final ExportTransactionsCsv exportTransactionsCsv;

  late final ExportFileActionsLocalDataSource exportFileActionsLocalDataSource;
  late final ExportFileActionsRepository exportFileActionsRepository;
  late final ShareExportFile shareExportFile;
  late final OpenExportFile openExportFile;
  late final CopyExportFilePath copyExportFilePath;
  late final ExportFileActionsController exportFileActionsController;

  final DatabaseHelper _databaseHelper;

  ExportModule({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<void> register() async {
    exportBackupLocalDataSource =
        ExportBackupLocalDataSourceImpl(_databaseHelper);
    exportBackupRepository =
        ExportBackupRepositoryImpl(exportBackupLocalDataSource);
    exportBackupJson = ExportBackupJson(exportBackupRepository);
    exportTransactionsCsv = ExportTransactionsCsv(exportBackupRepository);

    exportFileActionsLocalDataSource =
        const ExportFileActionsLocalDataSourceImpl();
    exportFileActionsRepository =
        ExportFileActionsRepositoryImpl(exportFileActionsLocalDataSource);
    shareExportFile = ShareExportFile(exportFileActionsRepository);
    openExportFile = OpenExportFile(exportFileActionsRepository);
    copyExportFilePath = CopyExportFilePath(exportFileActionsRepository);
    exportFileActionsController = ExportFileActionsController(
      shareExportFile: shareExportFile,
      openExportFile: openExportFile,
      copyExportFilePath: copyExportFilePath,
    );
  }
}
