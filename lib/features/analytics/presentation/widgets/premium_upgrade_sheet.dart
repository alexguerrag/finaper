import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/premium_package.dart';
import '../controllers/paywall_controller.dart';

/// Bottom sheet de paywall reutilizable.
///
/// Mostrar con:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: AppTheme.surfaceElevated,
///   shape: const RoundedRectangleBorder(
///     borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
///   ),
///   builder: (_) => PremiumUpgradeSheet(
///     paywallController: AnalyticsRegistry.module.paywallController,
///   ),
/// );
/// ```
class PremiumUpgradeSheet extends StatefulWidget {
  const PremiumUpgradeSheet({super.key, required this.paywallController});

  final PaywallController paywallController;

  @override
  State<PremiumUpgradeSheet> createState() => _PremiumUpgradeSheetState();
}

class _PremiumUpgradeSheetState extends State<PremiumUpgradeSheet> {
  @override
  void initState() {
    super.initState();
    widget.paywallController.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.paywallController.loadPackages();
    });
  }

  @override
  void dispose() {
    widget.paywallController.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _onPurchase() async {
    final outcome = await widget.paywallController.purchaseSelected();
    if (!mounted) return;
    if (outcome == PaywallOutcome.success) {
      Navigator.pop(context);
    }
    // cancelled → sin feedback agresivo
    // error → errorMessage ya visible en el sheet
  }

  Future<void> _onRestore() async {
    final outcome = await widget.paywallController.restorePurchases();
    if (!mounted) return;
    if (outcome == PaywallOutcome.success) {
      Navigator.pop(context);
    }
    // noRestore / error → errorMessage ya visible en el sheet
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.paywallController;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Handle(),
            const SizedBox(height: 20),
            _PremiumIcon(),
            const SizedBox(height: 14),
            Text(
              'FINAPER Premium',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lleva tus finanzas al siguiente nivel',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 20),
            const _BenefitsList(),
            const SizedBox(height: 20),
            if (ctrl.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              )
            else if (ctrl.packages.isEmpty) ...[
              _UnavailableState(),
              const SizedBox(height: 10),
              _RestoreButton(
                isPurchasing: ctrl.isPurchasing,
                onTap: _onRestore,
              ),
            ] else ...[
              _PackageSelector(
                packages: ctrl.packages,
                selected: ctrl.selectedPackage,
                onSelect: ctrl.selectPackage,
              ),
              const SizedBox(height: 16),
              _SubscribeButton(
                isPurchasing: ctrl.isPurchasing,
                onTap: _onPurchase,
              ),
              const SizedBox(height: 10),
              _RestoreButton(
                isPurchasing: ctrl.isPurchasing,
                onTap: _onRestore,
              ),
            ],
            if (ctrl.errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: ctrl.errorMessage!),
            ],
            const SizedBox(height: 12),
            _LegalNote(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets privados
// ---------------------------------------------------------------------------

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _PremiumIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.workspace_premium_rounded,
        color: AppTheme.primary,
        size: 32,
      ),
    );
  }
}

class _BenefitsList extends StatelessWidget {
  const _BenefitsList();

  static const _benefits = [
    'Comparación mensual de ingresos y gastos',
    'Proyección de cierre de mes',
    'Análisis automático de tus finanzas',
    'Reportes avanzados por categoría y período',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _benefits
          .map(
            (b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PackageSelector extends StatelessWidget {
  const _PackageSelector({
    required this.packages,
    required this.selected,
    required this.onSelect,
  });

  final List<PremiumPackage> packages;
  final PremiumPackage? selected;
  final void Function(PremiumPackage) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: packages
          .map(
            (p) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: packages.indexOf(p) == 0 ? 0 : 6,
                  right: packages.indexOf(p) == packages.length - 1 ? 0 : 6,
                ),
                child: _PackageCard(
                  package: p,
                  isSelected: selected?.id == p.id,
                  onTap: () => onSelect(p),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  final PremiumPackage package;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAnnual = package.period == PremiumPackagePeriod.annual;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAnnual)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Popular',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            Text(
              package.title,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              package.priceString,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({required this.isPurchasing, required this.onTap});

  final bool isPurchasing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isPurchasing ? null : onTap,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isPurchasing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Suscribirse',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _RestoreButton extends StatelessWidget {
  const _RestoreButton({required this.isPurchasing, required this.onTap});

  final bool isPurchasing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isPurchasing ? null : onTap,
      child: Text(
        'Restaurar compra',
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurfaceMuted,
        ),
      ),
    );
  }
}

class _UnavailableState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 36,
            color: AppTheme.onSurfaceMuted,
          ),
          const SizedBox(height: 10),
          Text(
            'Las suscripciones no están disponibles en este momento.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppTheme.onSurfaceMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: GoogleFonts.manrope(
          fontSize: 12,
          color: Colors.red.shade300,
        ),
      ),
    );
  }
}

class _LegalNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'La suscripción se renueva automáticamente. Cancela cuando quieras desde la tienda.',
      textAlign: TextAlign.center,
      style: GoogleFonts.manrope(
        fontSize: 11,
        color: AppTheme.onSurfaceMuted,
        height: 1.4,
      ),
    );
  }
}
