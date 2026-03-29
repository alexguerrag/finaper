import '../entities/export_file_entity.dart';

abstract class ExportFileActionsRepository {
  Future<void> shareFile(ExportFileEntity file);

  Future<void> openFile(ExportFileEntity file);

  Future<void> copyFilePath(ExportFileEntity file);
}
