import '../../domain/entities/export_file_entity.dart';
import '../../domain/repositories/export_file_actions_repository.dart';
import '../local/export_file_actions_local_datasource.dart';

class ExportFileActionsRepositoryImpl implements ExportFileActionsRepository {
  const ExportFileActionsRepositoryImpl(this._localDataSource);

  final ExportFileActionsLocalDataSource _localDataSource;

  @override
  Future<void> shareFile(ExportFileEntity file) {
    return _localDataSource.shareFile(file);
  }

  @override
  Future<void> openFile(ExportFileEntity file) {
    return _localDataSource.openFile(file);
  }

  @override
  Future<void> copyFilePath(ExportFileEntity file) {
    return _localDataSource.copyFilePath(file);
  }
}
