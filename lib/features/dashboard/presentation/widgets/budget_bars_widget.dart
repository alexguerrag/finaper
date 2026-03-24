import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/di/app_services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../budgets/domain/entities/budget_entity.dart';
import '../../../budgets/domain/usecases/get_budgets_by_month.dart';
import '../../../budgets/domain/utils/budget_month_key.dart';

class BudgetBarsWidget extends StatefulWidget {
  const BudgetBarsWidget({
    super.key,
    required this.refreshToken,
    this.onManagePressed,
  });

  final int refreshToken;
  final VoidCallback? onManagePressed;

  @override
  State<BudgetBarsWidget> createState() => _BudgetBarsWidgetState();
}

class _BudgetBarsWidgetState extends State<BudgetBarsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;
  late final GetBudgetsByMonth _getBudgetsByMonth;

  bool _isLoading = true;
  List<BudgetEntity> _budgets = <BudgetEntity>[];

  @override
  void initState() {
    super.initState();
    _getBudgetsByMonth = AppServices.instance.getBudgetsByMonth;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _anim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _loadBudgets();
  }

  @override
  void didUpdateWidget(covariant BudgetBarsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadBudgets();
    }
  }

  Future<void> _loadBudgets() async {
    try {
      final monthKey = budgetMonthKeyFromDate(DateTime.now());
      final budgets = await _getBudgetsByMonth(monthKey: monthKey);

      budgets.sort((a, b) => b.progress.compareTo(a.progress));

      if (!mounted) return;

      setState(() {
        _budgets = budgets.take(4).toList();
        _isLoading = false;
      });

      _controller.forward(from: 0);
    } catch (e, s) {
      debugPrint('BudgetBarsWidget error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _budgets = <BudgetEntity>[];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Presupuestos',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                  if (widget.onManagePressed != null)
                    TextButton(
                      onPressed: widget.onManagePressed,
                      child: const Text('Gestionar'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_budgets.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.savings_outlined,
                        color: AppTheme.onSurfaceMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aún no tienes presupuestos para este mes.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Crea uno para empezar a medir el consumo por categoría.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppTheme.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, child) => Column(
                    children: _budgets.map((budget) {
                      final ratio = budget.progress.clamp(0.0, 1.0);
                      final isWarning = budget.progress >= 0.8;
                      final displayColor =
                          budget.isExceeded ? AppTheme.expense : budget.color;
                      final accentColor =
                          isWarning ? AppTheme.warning : displayColor;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: displayColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(
                                    budget.isExceeded
                                        ? Icons.warning_amber_rounded
                                        : Icons.pie_chart_rounded,
                                    size: 16,
                                    color: displayColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    budget.categoryName,
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$${budget.spentAmount.toStringAsFixed(0)} / \$${budget.amountLimit.toStringAsFixed(0)}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: ratio * _anim.value,
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${(budget.progress * 100).toStringAsFixed(0)}% utilizado',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    color: accentColor.withValues(alpha: 0.90),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
