import 'package:finaper/features/export_backup/di/export_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ExportModule registers dependencies', () async {
    final module = ExportModule();

    await module.register();

    expect(module.exportBackupLocalDataSource, isNotNull);
    expect(module.exportBackupRepository, isNotNull);
    expect(module.exportBackupJson, isNotNull);
    expect(module.exportTransactionsCsv, isNotNull);
    expect(module.pickBackupRestorePreview, isNotNull);
    expect(module.restoreBackupJson, isNotNull);
    expect(module.exportFileActionsLocalDataSource, isNotNull);
    expect(module.exportFileActionsRepository, isNotNull);
    expect(module.shareExportFile, isNotNull);
    expect(module.openExportFile, isNotNull);
    expect(module.copyExportFilePath, isNotNull);
    expect(module.exportFileActionsController, isNotNull);
  });
}
