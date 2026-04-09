import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardFinancialSnapshotWidget extends StatelessWidget {
  const DashboardFinancialSnapshotWidget({
    super.key,
    required this.periodLabel,
    required this.balance,
    required this.income,
    required this.expense,
    required this.transactionCount,
    required this.onOpenTransactions,
  });

  final String periodLabel;
  final double balance;
  final double income;
  final double expense;
  final int transactionCount;
  final VoidCallback onOpenTransactions;

  @override
  Widget build(BuildContext context) {
    final balanceColor = balance >= 0 ? AppTheme.income : AppTheme.expense;
    final balancePrefix = balance >= 0 ? '' : '-';
    final balanceText =
        '$balancePrefix${AppFormatters.formatCurrency(balance.abs())}';

    final transactionLabel = transactionCount == 1
        ? '1 movimiento registrado'
        : '$transactionCount movimientos registrados';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  periodLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              Text(
                transactionLabel,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Balance reciente',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            balanceText,
            style: GoogleFonts.manrope(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1,
              color: balanceColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SnapshotMetricItem(
                  label: 'Ingresos',
                  value: AppFormatters.formatCurrency(income),
                  color: AppTheme.income,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SnapshotMetricItem(
                  label: 'Gastos',
                  value: AppFormatters.formatCurrency(expense),
                  color: AppTheme.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpenTransactions,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                'Ver movimientos',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetricItem extends StatelessWidget {
  const _SnapshotMetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
