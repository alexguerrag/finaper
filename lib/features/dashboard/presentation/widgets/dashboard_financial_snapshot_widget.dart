import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardFinancialSnapshotWidget extends StatelessWidget {
  const DashboardFinancialSnapshotWidget({
    super.key,
    required this.monthLabel,
    required this.consolidatedBalance,
    required this.netFlow,
    required this.income,
    required this.expense,
    required this.canGoToNextMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onGoToAccounts,
  });

  final String monthLabel;
  final double consolidatedBalance;
  final double netFlow;
  final double income;
  final double expense;
  final bool canGoToNextMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback? onGoToAccounts;

  @override
  Widget build(BuildContext context) {
    final isPositiveFlow = netFlow >= 0;
    final flowColor = isPositiveFlow ? AppTheme.income : AppTheme.expense;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthNavigator(
            label: monthLabel,
            canGoToNextMonth: canGoToNextMonth,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: onNextMonth,
          ),
          const SizedBox(height: 18),
          Text(
            'Saldo actual',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onGoToAccounts,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    AppFormatters.formatCurrency(consolidatedBalance),
                    style: GoogleFonts.manrope(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: -0.8,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                if (onGoToAccounts != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppTheme.onSurfaceMuted,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          _SnapshotMetricRow(
            label: 'Ingresos',
            value: AppFormatters.formatCurrency(income),
            color: AppTheme.income,
          ),
          const SizedBox(height: 10),
          _SnapshotMetricRow(
            label: 'Gastos',
            value: AppFormatters.formatCurrency(expense),
            color: AppTheme.expense,
          ),
          const SizedBox(height: 10),
          _SnapshotMetricRow(
            label: 'Flujo del mes',
            value: _formatSignedCurrency(netFlow),
            color: flowColor,
            bold: true,
          ),
        ],
      ),
    );
  }

  String _formatSignedCurrency(double value) {
    final formatted = AppFormatters.formatCurrency(value.abs());
    if (value > 0) return '+$formatted';
    if (value < 0) return '-$formatted';
    return AppFormatters.formatCurrency(0);
  }
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.label,
    required this.canGoToNextMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final String label;
  final bool canGoToNextMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MonthButton(
          icon: Icons.chevron_left_rounded,
          onPressed: onPreviousMonth,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _MonthButton(
          icon: Icons.chevron_right_rounded,
          onPressed: canGoToNextMonth ? onNextMonth : null,
        ),
      ],
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isEnabled ? 0.05 : 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: isEnabled ? 0.08 : 0.04),
          ),
        ),
        child: Icon(
          icon,
          color: isEnabled
              ? AppTheme.onSurface
              : AppTheme.onSurfaceMuted.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _SnapshotMetricRow extends StatelessWidget {
  const _SnapshotMetricRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
