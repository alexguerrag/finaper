import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/backup_validation_result_entity.dart';

class RestoreBackupDialog extends StatelessWidget {
  const RestoreBackupDialog({
    super.key,
    required this.validationResult,
  });

  final BackupValidationResultEntity validationResult;

  @override
  Widget build(BuildContext context) {
    final preview = validationResult.preview;

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(
        'Restaurar respaldo',
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w800,
          color: AppTheme.onSurface,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow(
              label: 'Archivo',
              value: preview.fileName,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Exportado',
              value: _formatDate(preview.exportedAt),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'DB backup',
              value: preview.databaseVersion.toString(),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Formato backup',
              value: preview.backupFormatVersion.toString(),
            ),
            const SizedBox(height: 16),
            _CountBlock(
              title: 'Contenido',
              counts: [
                'Cuentas: ${preview.accountsCount}',
                'Categorías: ${preview.categoriesCount}',
                'Movimientos: ${preview.transactionsCount}',
                'Presupuestos: ${preview.budgetsCount}',
                'Metas: ${preview.goalsCount}',
                'Recurrentes: ${preview.recurringTransactionsCount}',
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.24),
                ),
              ),
              child: Text(
                'Esta acción reemplazará todos los datos actuales de la app por el contenido del respaldo seleccionado.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
            if (validationResult.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: validationResult.warnings
                      .map(
                        (warning) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '• $warning',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text('Restaurar ahora'),
        ),
      ],
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'No disponible';
    }

    final local = value.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString().padLeft(4, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');

    return '$dd/$mm/$yyyy $hh:$min';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _CountBlock extends StatelessWidget {
  const _CountBlock({
    required this.title,
    required this.counts,
  });

  final String title;
  final List<String> counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ...counts.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                item,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
