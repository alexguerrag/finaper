import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../budgets/di/budgets_registry.dart';
import '../../../budgets/domain/entities/budget_entity.dart';
import '../../../budgets/domain/usecases/get_budgets_by_month.dart';
import '../../../budgets/domain/utils/budget_month_key.dart';

class BudgetAlertBannerWidget extends StatefulWidget {
  const BudgetAlertBannerWidget({
    super.key,
    required this.refreshToken,
    this.onManagePressed,
  });

  final int refreshToken;
  final VoidCallback? onManagePressed;

  @override
  State<BudgetAlertBannerWidget> createState() =>
      _BudgetAlertBannerWidgetState();
}

class _BudgetAlertBannerWidgetState extends State<BudgetAlertBannerWidget> {
  late final GetBudgetsByMonth _getBudgetsByMonth;

  bool _isLoading = true;
  BudgetEntity? _priorityBudget;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _getBudgetsByMonth = BudgetsRegistry.module.getBudgetsByMonth;
    _loadAlert();
  }

  @override
  void didUpdateWidget(covariant BudgetAlertBannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshToken != widget.refreshToken) {
      _dismissed = false;
      _loadAlert();
    }
  }

  Future<void> _loadAlert() async {
    try {
      final monthKey = budgetMonthKeyFromDate(DateTime.now());
      final budgets = await _getBudgetsByMonth(monthKey: monthKey);

      budgets.sort((a, b) => b.progress.compareTo(a.progress));

      final candidate = budgets.cast<BudgetEntity?>().firstWhere(
            (budget) => budget != null && budget.progress >= 0.8,
            orElse: () => null,
          );

      if (!mounted) return;

      setState(() {
        _priorityBudget = candidate;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('BudgetAlertBannerWidget error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _priorityBudget = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _dismissed || _priorityBudget == null) {
      return const SizedBox.shrink();
    }

    final budget = _priorityBudget!;
    final progressPercent = (budget.progress * 100).toStringAsFixed(0);
    final alertColor = budget.isExceeded ? AppTheme.expense : AppTheme.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alertColor.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              budget.isExceeded
                  ? Icons.priority_high_rounded
                  : Icons.warning_amber_rounded,
              size: 16,
              color: alertColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.isExceeded
                      ? 'Presupuesto excedido'
                      : 'Alerta de presupuesto',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: alertColor,
                  ),
                ),
                Text(
                  '${budget.categoryName} al $progressPercent% del límite mensual',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onManagePressed != null)
            TextButton(
              onPressed: widget.onManagePressed,
              child: const Text('Ver'),
            ),
          IconButton(
            onPressed: () {
              setState(() {
                _dismissed = true;
              });
            },
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppTheme.onSurfaceMuted,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}
