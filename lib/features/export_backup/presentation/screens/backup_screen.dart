import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/di/settings_registry.dart';
import '../../di/export_registry.dart';
import '../../domain/entities/export_file_entity.dart';
import '../../domain/usecases/export_backup_json.dart';
import '../../domain/usecases/export_transactions_csv.dart';
import '../../domain/usecases/pick_backup_restore_preview.dart';
import '../../domain/usecases/restore_backup_json.dart';
import '../controllers/export_file_actions_controller.dart';
import '../widgets/export_file_actions_dialog.dart';
import '../widgets/restore_backup_dialog.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late final ExportBackupJson _exportBackupJson;
  late final ExportTransactionsCsv _exportTransactionsCsv;
  late final PickBackupRestorePreview _pickBackupRestorePreview;
  late final RestoreBackupJson _restoreBackupJson;
  late final ExportFileActionsController _exportFileActionsController;

  bool _isExportingBackup = false;
  bool _isExportingCsv = false;
  bool _isRestoringBackup = false;

  bool get _isBusy =>
      _isExportingBackup || _isExportingCsv || _isRestoringBackup;

  @override
  void initState() {
    super.initState();
    _exportBackupJson = ExportRegistry.module.exportBackupJson;
    _exportTransactionsCsv = ExportRegistry.module.exportTransactionsCsv;
    _pickBackupRestorePreview = ExportRegistry.module.pickBackupRestorePreview;
    _restoreBackupJson = ExportRegistry.module.restoreBackupJson;
    _exportFileActionsController =
        ExportRegistry.module.exportFileActionsController;
  }

  Future<void> _exportBackup() async {
    if (_isExportingBackup) return;
    setState(() => _isExportingBackup = true);
    try {
      final file = await _exportBackupJson();
      if (!mounted) return;
      await _showExportDialog(title: 'Respaldo JSON generado', file: file);
    } catch (e, s) {
      debugPrint('BackupScreen _exportBackup error: $e');
      debugPrintStack(stackTrace: s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar el respaldo JSON.')),
      );
    } finally {
      if (mounted) setState(() => _isExportingBackup = false);
    }
  }

  Future<void> _exportCsv() async {
    if (_isExportingCsv) return;
    setState(() => _isExportingCsv = true);
    try {
      final file = await _exportTransactionsCsv();
      if (!mounted) return;
      await _showExportDialog(
          title: 'CSV de transacciones generado', file: file);
    } catch (e, s) {
      debugPrint('BackupScreen _exportCsv error: $e');
      debugPrintStack(stackTrace: s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo generar el CSV de transacciones.')),
      );
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  Future<void> _restoreBackup() async {
    if (_isRestoringBackup) return;
    setState(() => _isRestoringBackup = true);
    try {
      final validationResult = await _pickBackupRestorePreview();
      if (!mounted || validationResult == null) return;

      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (_) => RestoreBackupDialog(validationResult: validationResult),
      );
      if (!mounted || shouldRestore != true) return;

      await _restoreBackupJson(validationResult.payload);
      if (!mounted) return;

      await SettingsRegistry.module.controller.load();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Respaldo restaurado correctamente.')),
      );
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
    } on FormatException catch (e, s) {
      debugPrint('BackupScreen _restoreBackup format error: $e');
      debugPrintStack(stackTrace: s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e, s) {
      debugPrint('BackupScreen _restoreBackup error: $e');
      debugPrintStack(stackTrace: s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo restaurar el respaldo seleccionado.')),
      );
    } finally {
      if (mounted) setState(() => _isRestoringBackup = false);
    }
  }

  Future<void> _showExportDialog({
    required String title,
    required ExportFileEntity file,
  }) async {
    _exportFileActionsController.clearError();
    await showDialog<void>(
      context: context,
      builder: (_) => ExportFileActionsDialog(
        title: title,
        file: file,
        controller: _exportFileActionsController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Datos y respaldo',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BackupCard(
            icon: Icons.backup_rounded,
            label: 'Exportar respaldo JSON',
            subtitle: 'Copia completa de todos tus datos',
            loading: _isExportingBackup,
            busy: _isBusy,
            onTap: _exportBackup,
          ),
          const SizedBox(height: 12),
          _BackupCard(
            icon: Icons.table_view_rounded,
            label: 'Exportar transacciones CSV',
            subtitle: 'Compatible con Excel y hojas de cálculo',
            loading: _isExportingCsv,
            busy: _isBusy,
            onTap: _exportCsv,
          ),
          const SizedBox(height: 24),
          _RestoreCard(
            loading: _isRestoringBackup,
            busy: _isBusy,
            onTap: _restoreBackup,
          ),
        ],
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.loading,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool loading;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppTheme.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.onSurfaceMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestoreCard extends StatelessWidget {
  const _RestoreCard({
    required this.loading,
    required this.busy,
    required this.onTap,
  });

  final bool loading;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.restore_rounded,
                        color: AppTheme.warning, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restaurar respaldo',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      'Reemplaza todos los datos actuales con el respaldo',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppTheme.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.onSurfaceMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
