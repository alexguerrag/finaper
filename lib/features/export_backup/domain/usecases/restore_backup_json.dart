import '../repositories/export_backup_repository.dart';

class RestoreBackupJson {
  const RestoreBackupJson(this._repository);

  final ExportBackupRepository _repository;

  Future<void> call(Map<String, dynamic> payload) {
    return _repository.restoreBackupJson(payload);
  }
}
