import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/local/dashboard_local_datasource.dart';

class DashboardTopExpenseCategoriesWidget extends StatelessWidget {
  const DashboardTopExpenseCategoriesWidget({
    super.key,
    required this.categories,
    required this.totalExpense,
  });

  final List<DashboardExpenseCategorySummary> categories;

  /// Real month expense total — may be higher than the sum of [categories]
  /// when there are more than 4 expense categories.
  final double totalExpense;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
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
            Text(
              'Distribución de gastos',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay gastos registrados.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
      );
    }

    final sorted = [...categories]
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Container(
      padding: const EdgeInsets.all(18),
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
          Text(
            'Distribución de gastos',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Top 5 · mes en curso',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 14),
          _ExpenseTotalHeader(totalAmount: totalExpense),
          const SizedBox(height: 16),
          ...sorted.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ExpenseCategoryBarRow(
                category: category,
                color: _resolveCategoryColor(category),
              ),
            ),
          ),
          Builder(builder: (context) {
            final listedTotal =
                sorted.fold(0.0, (s, c) => s + c.amount);
            final remainder = totalExpense - listedTotal;
            if (remainder <= 0) return const SizedBox.shrink();
            final remainderPct = totalExpense > 0
                ? remainder / totalExpense
                : 0.0;
            return _OtherCategoriesRow(
              amount: remainder,
              percentage: remainderPct,
            );
          }),
        ],
      ),
    );
  }

  Color _resolveCategoryColor(DashboardExpenseCategorySummary category) {
    if (category.colorValue != null && category.colorValue != 0) {
      return Color(category.colorValue!).withValues(alpha: 1.0);
    }

    return AppTheme.primary;
  }
}

class _ExpenseTotalHeader extends StatelessWidget {
  const _ExpenseTotalHeader({
    required this.totalAmount,
  });

  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.expense,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Total gastado',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ),
          Text(
            AppFormatters.formatCurrency(totalAmount),
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCategoryBarRow extends StatelessWidget {
  const _ExpenseCategoryBarRow({
    required this.category,
    required this.color,
  });

  final DashboardExpenseCategorySummary category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percentage = (category.percentage * 100).round();
    final percentageLabel = '$percentage%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              percentageLabel,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: category.percentage.clamp(0, 1).toDouble(),
            minHeight: 9,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppFormatters.formatCurrency(category.amount),
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}

class _OtherCategoriesRow extends StatelessWidget {
  const _OtherCategoriesRow({
    required this.amount,
    required this.percentage,
  });

  final double amount;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceMuted.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Otras categorías',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(percentage * 100).round()}%',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percentage.clamp(0, 1).toDouble(),
            minHeight: 9,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.onSurfaceMuted.withValues(alpha: 0.35),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppFormatters.formatCurrency(amount),
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}
