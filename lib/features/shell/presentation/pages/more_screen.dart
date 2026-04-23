import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.onRefreshDashboard});

  final Future<void> Function() onRefreshDashboard;

  Future<void> _navigate(BuildContext context, String route) async {
    await Navigator.pushNamed(context, route);
    if (!context.mounted) return;
    await onRefreshDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Más',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _MoreTile(
            icon: Icons.flag_rounded,
            label: 'Metas',
            subtitle: 'Seguimiento de objetivos de ahorro',
            onTap: () => _navigate(context, AppRoutes.goals),
          ),
          _MoreTile(
            icon: Icons.label_outlined,
            label: 'Categorías',
            subtitle: 'Organiza tus movimientos por tipo',
            onTap: () => _navigate(context, AppRoutes.categories),
          ),
          _MoreTile(
            icon: Icons.repeat_rounded,
            label: 'Recurrentes',
            subtitle: 'Transacciones programadas',
            onTap: () => _navigate(context, AppRoutes.recurringTransactions),
          ),
          _MoreTile(
            icon: Icons.backup_rounded,
            label: 'Datos y respaldo',
            subtitle: 'Exportar respaldo, CSV y restaurar',
            onTap: () => _navigate(context, AppRoutes.backup),
          ),
          _MoreTile(
            icon: Icons.settings_outlined,
            label: 'Ajustes',
            subtitle: 'Moneda, idioma y preferencias',
            onTap: () => _navigate(context, AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.onSurface, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
