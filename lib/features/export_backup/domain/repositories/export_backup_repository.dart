import '../entities/backup_validation_result_entity.dart';
import '../entities/export_file_entity.dart';

abstract class ExportBackupRepository {
  Future<ExportFileEntity> exportBackupJson();

  Future<ExportFileEntity> exportTransactionsCsv();

  Future<BackupValidationResultEntity?> pickBackupRestorePreview();

  Future<void> restoreBackupJson(Map<String, dynamic> payload);
}
