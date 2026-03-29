import '../../domain/entities/export_file_entity.dart';

class ExportFileModel extends ExportFileEntity {
  const ExportFileModel({
    required super.fileName,
    required super.filePath,
    required super.mimeType,
    required super.createdAt,
  });

  factory ExportFileModel.fromEntity(ExportFileEntity entity) {
    return ExportFileModel(
      fileName: entity.fileName,
      filePath: entity.filePath,
      mimeType: entity.mimeType,
      createdAt: entity.createdAt,
    );
  }
}
