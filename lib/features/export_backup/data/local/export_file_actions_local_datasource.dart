import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/export_file_entity.dart';

abstract class ExportFileActionsLocalDataSource {
  Future<void> shareFile(ExportFileEntity file);

  Future<void> openFile(ExportFileEntity file);

  Future<void> copyFilePath(ExportFileEntity file);
}

class ExportFileActionsLocalDataSourceImpl
    implements ExportFileActionsLocalDataSource {
  const ExportFileActionsLocalDataSourceImpl();

  @override
  Future<void> shareFile(ExportFileEntity file) async {
    try {
      final ioFile = File(file.filePath);

      if (!await ioFile.exists()) {
        throw FileSystemException('Archivo no encontrado', file.filePath);
      }

      await Share.shareXFiles(
        [XFile(file.filePath)],
        subject: file.fileName,
        text: 'Archivo exportado desde Finaper: ${file.fileName}',
      );
    } catch (e, s) {
      debugPrint('ExportFileActionsLocalDataSource.shareFile error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> openFile(ExportFileEntity file) async {
    try {
      final ioFile = File(file.filePath);

      if (!await ioFile.exists()) {
        throw FileSystemException('Archivo no encontrado', file.filePath);
      }

      final result = await OpenFilex.open(file.filePath);

      if (result.type != ResultType.done) {
        final message = result.message.trim().isEmpty
            ? 'No se pudo abrir el archivo (${result.type.name}).'
            : result.message.trim();

        throw Exception(message);
      }
    } catch (e, s) {
      debugPrint('ExportFileActionsLocalDataSource.openFile error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> copyFilePath(ExportFileEntity file) async {
    try {
      await Clipboard.setData(
        ClipboardData(text: file.filePath),
      );
    } catch (e, s) {
      debugPrint('ExportFileActionsLocalDataSource.copyFilePath error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
