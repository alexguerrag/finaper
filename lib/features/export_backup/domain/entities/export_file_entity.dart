import 'package:equatable/equatable.dart';

class ExportFileEntity extends Equatable {
  const ExportFileEntity({
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.createdAt,
  });

  final String fileName;
  final String filePath;
  final String mimeType;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        fileName,
        filePath,
        mimeType,
        createdAt,
      ];
}
