import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../budgets/di/budgets_registry.dart';
import '../../../budgets/domain/entities/budget_entity.dart';
import '../../../budgets/domain/usecases/get_budgets_by_month.dart';
import '../../../budgets/domain/utils/budget_month_key.dart';

class DashboardBudgetSummaryWidget extends StatefulWidget {
  const DashboardBudgetSummaryWidget({
    super.key,
    required this.month,
    required this.refreshToken,
    this.onManagePressed,
  });

  final DateTime month;
  final int refreshToken;
  final VoidCallback? onManagePressed;

  @override
  State<DashboardBudgetSummaryWidget> createState() =>
      _DashboardBudgetSummaryWidgetState();
}

class _DashboardBudgetSummaryWidgetState
    extends State<DashboardBudgetSummaryWidget> {
  late final GetBudgetsByMonth _getBudgetsByMonth;

  bool _isLoading = true;
  List<BudgetEntity> _budgets = const <BudgetEntity>[];

  @override
  void initState() {
    super.initState();
    _getBudgetsByMonth = BudgetsRegistry.module.getBudgetsByMonth;
    _loadBudgets();
  }

  @override
  void didUpdateWidget(covariant DashboardBudgetSummaryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldMonthKey = budgetMonthKeyFromDate(oldWidget.month);
    final newMonthKey = budgetMonthKeyFromDate(widget.month);

    if (oldWidget.refreshToken != widget.refreshToken ||
        oldMonthKey != newMonthKey) {
      _loadBudgets();
    }
  }

  Future<void> _loadBudgets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final budgets = await _getBudgetsByMonth(
        monthKey: budgetMonthKeyFromDate(widget.month),
      );

      if (!mounted) return;

      setState(() {
        _budgets = budgets;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('DashboardBudgetSummaryWidget error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _budgets = const <BudgetEntity>[];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_budgets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.savings_outlined,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Presupuestos del mes',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Todavía no tienes presupuestos para este mes. Crear al menos los principales ayuda a entender mejor tu ritmo de gasto.',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      height: 1.35,
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                  if (widget.onManagePressed != null) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: widget.onManagePressed,
                      child: const Text('Crear presupuestos'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    final totalLimit = _budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.amountLimit,
    );

    final totalSpent = _budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.spentAmount,
    );

    final exceededCount = _budgets.where((budget) => budget.isExceeded).length;
    final riskCount = _budgets.where((budget) {
      return !budget.isExceeded && budget.progress >= 0.8;
    }).length;
    final healthyCount = _budgets.where((budget) {
      return budget.progress < 0.8;
    }).length;

    final balance = totalLimit - totalSpent;
    final isExceeded = balance < 0;
    final headlineColor = isExceeded ? AppTheme.expense : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Presupuestos del mes',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
              if (widget.onManagePressed != null)
                TextButton(
                  onPressed: widget.onManagePressed,
                  child: const Text('Ver'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isExceeded
                ? 'Vas ${AppFormatters.formatCurrency(balance.abs())} por encima del límite total.'
                : 'Te quedan ${AppFormatters.formatCurrency(balance)}',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: headlineColor,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: totalLimit > 0
                  ? (totalSpent / totalLimit).clamp(0.0, 1.0)
                  : 0,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(headlineColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BudgetSummaryMetric(
                  label: 'Presupuestado',
                  value: AppFormatters.formatCurrency(totalLimit),
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BudgetSummaryMetric(
                  label: 'Consumido',
                  value: AppFormatters.formatCurrency(totalSpent),
                  color: AppTheme.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _BudgetStatusPill(
                  label: 'Bien',
                  value: healthyCount,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BudgetStatusPill(
                  label: 'En riesgo',
                  value: riskCount,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BudgetStatusPill(
                  label: 'Excedidos',
                  value: exceededCount,
                  color: AppTheme.expense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetSummaryMetric extends StatelessWidget {
  const _BudgetSummaryMetric({
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
      padding: const EdgeInsets.all(14),
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
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetStatusPill extends StatelessWidget {
  const _BudgetStatusPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
