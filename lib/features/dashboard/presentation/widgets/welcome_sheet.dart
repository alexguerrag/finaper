import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class WelcomeSheet extends StatelessWidget {
  const WelcomeSheet({
    super.key,
    required this.onGoToAccounts,
    required this.onDismiss,
  });

  final VoidCallback onGoToAccounts;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¡Bienvenido a Finaper!',
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Para empezar, crea tu primera cuenta e ingresa tu saldo actual. Así Finaper podrá mostrarte un resumen real de tus finanzas desde el primer día.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                height: 1.55,
                color: AppTheme.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onGoToAccounts,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Crear mi primera cuenta',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onDismiss,
              child: Text(
                'Explorar primero',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
