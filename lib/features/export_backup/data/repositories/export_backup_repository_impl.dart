import '../../domain/entities/export_file_entity.dart';
import '../../domain/repositories/export_backup_repository.dart';
import '../local/export_backup_local_datasource.dart';

class ExportBackupRepositoryImpl implements ExportBackupRepository {
  const ExportBackupRepositoryImpl(this._localDataSource);

  final ExportBackupLocalDataSource _localDataSource;

  @override
  Future<ExportFileEntity> exportBackupJson() {
    return _localDataSource.exportBackupJson();
  }

  @override
  Future<ExportFileEntity> exportTransactionsCsv() {
    return _localDataSource.exportTransactionsCsv();
  }
}
