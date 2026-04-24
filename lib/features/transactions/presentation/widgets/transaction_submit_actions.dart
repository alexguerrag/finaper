import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class TransactionSubmitActions extends StatefulWidget {
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
  State<TransactionSubmitActions> createState() =>
      _TransactionSubmitActionsState();
}

class _TransactionSubmitActionsState extends State<TransactionSubmitActions> {
  bool _showCheck = false;

  Future<void> _handleSecondary() async {
    widget.onSecondaryPressed();
    setState(() => _showCheck = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _showCheck = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showSecondary) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.isSaving || !widget.isEnabled
                  ? null
                  : _handleSecondary,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _showCheck
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('check'),
                        color: AppTheme.income,
                      )
                    : const Icon(
                        Icons.add_task_rounded,
                        key: ValueKey('add'),
                      ),
              ),
              label: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  _showCheck ? '¡Guardado!' : 'Guardar y agregar otra',
                  key: ValueKey(_showCheck),
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: _showCheck ? AppTheme.income : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.isSaving || !widget.isEnabled
                ? null
                : widget.onPrimaryPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: widget.isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.primaryLabel,
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
