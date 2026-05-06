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

  /// Ni JSON ni CSV tienen app por defecto en Android: OpenFilex dispararía
  /// el diálogo del sistema con "tipo no admitido". Ocultamos "Abrir" para
  /// ambos formatos y dejamos Compartir como única acción.
  bool get _shareOnly =>
      widget.file.mimeType == 'application/json' ||
      widget.file.mimeType == 'text/csv' ||
      widget.file.fileName.endsWith('.json') ||
      widget.file.fileName.endsWith('.csv');

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  Future<void> _checkFileExists() async {
    setState(() => _checkingExists = true);
    try {
      _fileExists = await widget.controller.fileExists(widget.file);
    } catch (_) {
      _fileExists = false;
    } finally {
      if (mounted) setState(() => _checkingExists = false);
    }
  }

  Future<void> _handleOpenFile() async {
    final ok = await widget.controller.openFile(widget.file);
    if (!mounted) return;

    if (!ok) {
      final msg = widget.controller.errorMessage ??
          'No encontramos una app compatible para abrir este archivo. '
              'Puedes compartirlo o guardarlo en una ubicación segura.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _handleShareFile() async {
    final ok = await widget.controller.shareFile(widget.file);
    if (!mounted) return;

    if (!ok) {
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
        final canAct = !checking && exists && !isWorking;

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
              _DialogInfoRow(
                label: 'Ubicación',
                value: 'Guardado de forma privada en FINAPER',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exists
                          ? 'Listo para compartir. Usa el botón "Compartir" para enviarlo a Drive, Gmail u otra app.'
                          : 'El archivo no está disponible. Intenta exportar de nuevo.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppTheme.onSurfaceMuted,
                      ),
                    ),
                    if (exists) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 12,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Este archivo contiene información financiera. '
                              'Guárdalo solo en lugares seguros.',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: AppTheme.onSurfaceMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            if (!_shareOnly)
              TextButton(
                onPressed: canAct ? _handleOpenFile : null,
                child: const Text('Abrir'),
              ),
            FilledButton(
              onPressed: canAct ? _handleShareFile : null,
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
  const _DialogInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
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
