import 'backup_restore_preview_entity.dart';

class BackupValidationResultEntity {
  const BackupValidationResultEntity({
    required this.preview,
    required this.payload,
    this.warnings = const <String>[],
  });

  final BackupRestorePreviewEntity preview;
  final Map<String, dynamic> payload;
  final List<String> warnings;
}
