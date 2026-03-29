import '../entities/export_file_entity.dart';
import '../repositories/export_backup_repository.dart';

class ExportTransactionsCsv {
  const ExportTransactionsCsv(this._repository);

  final ExportBackupRepository _repository;

  Future<ExportFileEntity> call() {
    return _repository.exportTransactionsCsv();
  }
}
