import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/export_file_entity.dart';
import '../controllers/export_file_actions_controller.dart';

class ExportFileActionsDialog extends StatefulWidget {
  const ExportFileActionsDialog({
    super.key,
    required this.title,
    required this.file,
    required this.controller,
  });

  final String title;
  final ExportFileEntity file;
  final ExportFileActionsController controller;

  @override
  State<ExportFileActionsDialog> createState() =>
      _ExportFileActionsDialogState();
}

class _ExportFileActionsDialogState extends State<ExportFileActionsDialog> {
  bool _fileExists = false;
  bool _checkingExists = true;

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  Future<void> _checkFileExists() async {
    setState(() {
      _checkingExists = true;
    });

    try {
      _fileExists = await widget.controller.fileExists(widget.file);
    } catch (e, s) {
      debugPrint('ExportFileActionsDialog._checkFileExists error: $e');
      debugPrintStack(stackTrace: s);
      _fileExists = false;
    } finally {
      if (mounted) {
        setState(() {
          _checkingExists = false;
        });
      }
    }
  }

  Future<void> _handleCopyPath() async {
    final ok = await widget.controller.copyPath(widget.file);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruta copiada al portapapeles.'),
        ),
      );
    } else {
      final msg = widget.controller.errorMessage ??
          'No se pudo copiar la ruta al portapapeles.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _handleOpenFile() async {
    final ok = await widget.controller.openFile(widget.file);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Abriendo ${widget.file.fileName}...'),
        ),
      );
    } else {
      final msg = widget.controller.errorMessage ??
          'No se pudo abrir el archivo. Verifica que exista una app compatible.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _handleShareFile() async {
    final ok = await widget.controller.shareFile(widget.file);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compartiendo ${widget.file.fileName}...'),
        ),
      );
    } else {
      final msg =
          widget.controller.errorMessage ?? 'No se pudo compartir el archivo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final isWorking = widget.controller.isWorking;
        final checking = _checkingExists;
        final exists = _fileExists;
        final canOpenOrShare = !checking && exists && !isWorking;

        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(
            widget.title,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogInfoRow(
                label: 'Archivo',
                value: widget.file.fileName,
              ),
              const SizedBox(height: 12),
              _DialogInfoRow(
                label: 'Tipo',
                value: widget.file.mimeType,
              ),
              const SizedBox(height: 12),
              _DialogInfoRow(
                label: 'Estado',
                value: checking
                    ? 'Comprobando...'
                    : (exists ? 'Disponible' : 'No encontrado'),
              ),
              const SizedBox(height: 12),
              Text(
                'Ruta',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                widget.file.filePath,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  exists
                      ? 'Puedes compartir el archivo, abrirlo directamente o copiar su ruta.'
                      : 'El archivo no está disponible. Puedes copiar la ruta para ubicarlo o reintentar la exportación.',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
              ),
              if (widget.controller.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  widget.controller.errorMessage!,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isWorking ? null : _checkFileExists,
              child: const Text('Revisar'),
            ),
            TextButton(
              onPressed: isWorking ? null : _handleCopyPath,
              child: const Text('Copiar ruta'),
            ),
            TextButton(
              onPressed: canOpenOrShare ? _handleOpenFile : null,
              child: const Text('Abrir'),
            ),
            FilledButton(
              onPressed: canOpenOrShare ? _handleShareFile : null,
              child: isWorking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Compartir'),
            ),
          ],
        );
      },
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  const _DialogInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
