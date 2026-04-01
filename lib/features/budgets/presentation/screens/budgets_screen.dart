import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/budget_model.dart';
import '../../di/budgets_registry.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/usecases/get_budgets_by_month.dart';
import '../../domain/usecases/upsert_budget.dart';
import '../../domain/utils/budget_month_key.dart';
import '../widgets/add_budget_sheet.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late final GetBudgetsByMonth _getBudgetsByMonth;
  late final UpsertBudget _upsertBudget;

  bool _isLoading = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<BudgetEntity> _budgets = <BudgetEntity>[];

  String get _monthKey => budgetMonthKeyFromDate(_selectedMonth);

  @override
  void initState() {
    super.initState();
    _getBudgetsByMonth = BudgetsRegistry.module.getBudgetsByMonth;
    _upsertBudget = BudgetsRegistry.module.upsertBudget;
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    try {
      final budgets = await _getBudgetsByMonth(
        monthKey: _monthKey,
      );

      if (!mounted) return;

      setState(() {
        _budgets = budgets;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('BudgetsScreen load error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron cargar los presupuestos.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _changeMonth(int delta) async {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
      _isLoading = true;
    });

    await _loadBudgets();
  }

  Future<void> _openAddBudgetSheet() async {
    final result = await showModalBottomSheet<BudgetModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBudgetSheet(
        monthKey: _monthKey,
      ),
    );

    if (result == null) return;

    try {
      await _upsertBudget(result);

      if (!mounted) return;

      await _loadBudgets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Presupuesto guardado correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('BudgetsScreen upsert error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar el presupuesto.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  String _monthLabel(DateTime date) {
    return AppFormatters.formatMonthYear(date);
  }

  String _formatCurrency(double value) {
    return AppFormatters.formatCurrency(value);
  }

  @override
  Widget build(BuildContext context) {
    final totalLimit = _budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.amountLimit,
    );

    final totalSpent = _budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.spentAmount,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Presupuestos',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBudgetSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBudgets,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          _monthLabel(_selectedMonth),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _BudgetMetric(
                          label: 'Límite total',
                          value: totalLimit,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BudgetMetric(
                          label: 'Consumido',
                          value: totalSpent,
                          color: AppTheme.expense,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_budgets.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.savings_outlined,
                      size: 36,
                      color: AppTheme.onSurfaceMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Todavía no hay presupuestos para este mes.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Crea tu primer presupuesto mensual por categoría.',
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
              ..._budgets.map(
                (budget) {
                  final progress = budget.progress.clamp(0.0, 1.2);
                  final displayColor =
                      budget.isExceeded ? AppTheme.expense : budget.color;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: displayColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                budget.isExceeded
                                    ? Icons.warning_amber_rounded
                                    : Icons.pie_chart_rounded,
                                color: displayColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    budget.categoryName,
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    budget.isExceeded
                                        ? 'Límite superado'
                                        : 'Dentro del límite',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: budget.isExceeded
                                          ? AppTheme.expense
                                          : AppTheme.onSurfaceMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatCurrency(budget.amountLimit),
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: progress > 1 ? 1 : progress,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.08),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(displayColor),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Gastado: ${_formatCurrency(budget.spentAmount)}',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppTheme.onSurfaceMuted,
                              ),
                            ),
                            Text(
                              budget.isExceeded
                                  ? 'Exceso: ${_formatCurrency(budget.spentAmount - budget.amountLimit)}'
                                  : 'Disponible: ${_formatCurrency(budget.remainingAmount)}',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: budget.isExceeded
                                    ? AppTheme.expense
                                    : displayColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _BudgetMetric extends StatelessWidget {
  const _BudgetMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppFormatters.formatCurrency(value),
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
