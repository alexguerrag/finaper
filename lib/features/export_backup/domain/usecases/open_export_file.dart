import '../entities/export_file_entity.dart';
import '../repositories/export_file_actions_repository.dart';

class OpenExportFile {
  const OpenExportFile(this._repository);

  final ExportFileActionsRepository _repository;

  Future<void> call(ExportFileEntity file) {
    return _repository.openFile(file);
  }
}
