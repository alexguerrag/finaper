import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/export_file_entity.dart';
import '../../domain/usecases/copy_export_file_path.dart';
import '../../domain/usecases/open_export_file.dart';
import '../../domain/usecases/share_export_file.dart';

class ExportFileActionsController extends ChangeNotifier {
  ExportFileActionsController({
    required ShareExportFile shareExportFile,
    required OpenExportFile openExportFile,
    required CopyExportFilePath copyExportFilePath,
  })  : _shareExportFile = shareExportFile,
        _openExportFile = openExportFile,
        _copyExportFilePath = copyExportFilePath;

  final ShareExportFile _shareExportFile;
  final OpenExportFile _openExportFile;
  final CopyExportFilePath _copyExportFilePath;

  bool _isWorking = false;
  String? _errorMessage;

  bool get isWorking => _isWorking;
  String? get errorMessage => _errorMessage;

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> fileExists(ExportFileEntity file) async {
    try {
      return File(file.filePath).exists();
    } catch (e, s) {
      debugPrint('ExportFileActionsController.fileExists error: $e');
      debugPrintStack(stackTrace: s);
      return false;
    }
  }

  Future<bool> copyPath(ExportFileEntity file) {
    return _run(
      tag: 'copyPath',
      task: () => _copyExportFilePath(file),
      userError: 'No se pudo copiar la ruta al portapapeles.',
    );
  }

  Future<bool> openFile(ExportFileEntity file) {
    return _run(
      tag: 'openFile',
      task: () => _openExportFile(file),
      userError:
          'No se pudo abrir el archivo. Puede que no haya una app compatible instalada en este dispositivo. Puedes compartirlo o copiar la ruta.',
    );
  }

  Future<bool> shareFile(ExportFileEntity file) {
    return _run(
      tag: 'shareFile',
      task: () => _shareExportFile(file),
      userError: 'No se pudo compartir el archivo.',
    );
  }

  Future<bool> _run({
    required String tag,
    required Future<void> Function() task,
    required String userError,
  }) async {
    if (_isWorking) return false;

    _isWorking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await task();
      return true;
    } catch (e, s) {
      debugPrint('ExportFileActionsController.$tag error: $e');
      debugPrintStack(stackTrace: s);
      _errorMessage = userError;
      return false;
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }
}
