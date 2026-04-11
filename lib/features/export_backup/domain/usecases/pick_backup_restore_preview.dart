import '../entities/backup_validation_result_entity.dart';
import '../repositories/export_backup_repository.dart';

class PickBackupRestorePreview {
  const PickBackupRestorePreview(this._repository);

  final ExportBackupRepository _repository;

  Future<BackupValidationResultEntity?> call() {
    return _repository.pickBackupRestorePreview();
  }
}
