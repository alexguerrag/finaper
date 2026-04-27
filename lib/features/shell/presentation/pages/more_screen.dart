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
          const _SectionHeader(label: 'Herramientas'),
          _MoreTile(
            icon: Icons.savings_outlined,
            label: 'Presupuestos',
            subtitle: 'Límites de gasto por categoría',
            onTap: () => _navigate(context, AppRoutes.budgets),
          ),
          _MoreTile(
            icon: Icons.repeat_rounded,
            label: 'Recurrentes',
            subtitle: 'Pagos y cobros programados',
            onTap: () => _navigate(context, AppRoutes.recurringTransactions),
          ),
          _MoreTile(
            icon: Icons.flag_rounded,
            label: 'Metas',
            subtitle: 'Seguimiento de objetivos de ahorro',
            onTap: () => _navigate(context, AppRoutes.goals),
          ),
          const _SectionHeader(label: 'Configuración'),
          _MoreTile(
            icon: Icons.label_outlined,
            label: 'Categorías',
            subtitle: 'Organiza tus movimientos por tipo',
            onTap: () => _navigate(context, AppRoutes.categories),
          ),
          _MoreTile(
            icon: Icons.settings_outlined,
            label: 'Ajustes',
            subtitle: 'Moneda, idioma y preferencias',
            onTap: () => _navigate(context, AppRoutes.settings),
          ),
          const _SectionHeader(label: 'Datos'),
          _MoreTile(
            icon: Icons.backup_rounded,
            label: 'Datos y respaldo',
            subtitle: 'Exportar respaldo, CSV y restaurar',
            onTap: () => _navigate(context, AppRoutes.backup),
          ),
          const _SectionHeader(label: 'Ayuda'),
          const _HowItWorksCard(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4, left: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.onSurfaceMuted,
          letterSpacing: 0.8,
        ),
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

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                '¿Cómo funciona Finaper?',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _HowItWorksRow(
            icon: Icons.account_balance_wallet_rounded,
            concept: 'Cuentas',
            description: 'dónde tienes tu dinero',
          ),
          const SizedBox(height: 8),
          const _HowItWorksRow(
            icon: Icons.receipt_long_rounded,
            concept: 'Movimientos',
            description: 'lo que haces con él',
          ),
          const SizedBox(height: 8),
          const _HowItWorksRow(
            icon: Icons.savings_rounded,
            concept: 'Presupuestos',
            description: 'tu control mensual',
          ),
          const SizedBox(height: 8),
          const _HowItWorksRow(
            icon: Icons.repeat_rounded,
            concept: 'Recurrentes',
            description: 'lo que pagas o cobras cada mes',
          ),
          const SizedBox(height: 8),
          const _HowItWorksRow(
            icon: Icons.flag_rounded,
            concept: 'Metas',
            description: 'guarda dinero para algo específico',
          ),
          const SizedBox(height: 8),
          const _HowItWorksRow(
            icon: Icons.label_outlined,
            concept: 'Categorías',
            description: 'clasifica y etiqueta tus movimientos',
          ),
        ],
      ),
    );
  }
}

class _HowItWorksRow extends StatelessWidget {
  const _HowItWorksRow({
    required this.icon,
    required this.concept,
    required this.description,
  });

  final IconData icon;
  final String concept;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.onSurfaceMuted),
        const SizedBox(width: 10),
        Text(
          concept,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        Text(
          '  →  $description',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}
