import '../entities/export_file_entity.dart';

abstract class ExportBackupRepository {
  Future<ExportFileEntity> exportBackupJson();

  Future<ExportFileEntity> exportTransactionsCsv();
}
