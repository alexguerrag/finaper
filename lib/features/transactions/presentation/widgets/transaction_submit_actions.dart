import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class TransactionSubmitActions extends StatelessWidget {
  const TransactionSubmitActions({
    super.key,
    required this.isSaving,
    required this.isEnabled,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    this.showSecondary = true,
  });

  final bool isSaving;
  final bool isEnabled;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;
  final bool showSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSecondary) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSaving || !isEnabled ? null : onSecondaryPressed,
              icon: const Icon(Icons.add_task_rounded),
              label: Text(
                'Guardar y agregar otra',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isSaving || !isEnabled ? null : onPrimaryPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    primaryLabel,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
