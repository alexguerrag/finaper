import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/budget_model.dart';
import '../../di/budgets_registry.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/usecases/delete_budget.dart';
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
  late final DeleteBudget _deleteBudget;

  bool _isLoading = true;
  bool _isCopyingPreviousMonth = false;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<BudgetEntity> _budgets = <BudgetEntity>[];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String get _monthKey => budgetMonthKeyFromDate(_selectedMonth);

  DateTime get _previousMonth => DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );

  String get _previousMonthKey => budgetMonthKeyFromDate(_previousMonth);

  @override
  void initState() {
    super.initState();
    _getBudgetsByMonth = BudgetsRegistry.module.getBudgetsByMonth;
    _upsertBudget = BudgetsRegistry.module.upsertBudget;
    _deleteBudget = BudgetsRegistry.module.deleteBudget;
    _loadBudgets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      NotificationService.checkAndNotifyBudgets(budgets);
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

  Future<void> _openEditBudgetSheet(BudgetEntity budget) async {
    final result = await showModalBottomSheet<BudgetModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBudgetSheet(
        monthKey: _monthKey,
        initialBudget: budget,
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
            'Presupuesto actualizado correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('BudgetsScreen edit error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo actualizar el presupuesto.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _copyBudgetsFromPreviousMonth() async {
    if (_isCopyingPreviousMonth || _isLoading) return;

    setState(() {
      _isCopyingPreviousMonth = true;
    });

    try {
      final previousBudgets = await _getBudgetsByMonth(
        monthKey: _previousMonthKey,
      );

      if (previousBudgets.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No hay presupuestos en ${_monthLabel(_previousMonth)} para copiar.',
              style: GoogleFonts.manrope(),
            ),
          ),
        );
        return;
      }

      for (final budget in previousBudgets) {
        final now = DateTime.now();

        await _upsertBudget(
          BudgetModel(
            id: 'budget-${budget.categoryId}-$_monthKey',
            categoryId: budget.categoryId,
            categoryName: budget.categoryName,
            monthKey: _monthKey,
            amountLimit: budget.amountLimit,
            spentAmount: 0,
            color: budget.color,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      if (!mounted) return;

      await _loadBudgets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Presupuestos copiados desde ${_monthLabel(_previousMonth)}.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('BudgetsScreen copy previous month error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron copiar los presupuestos del mes anterior.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCopyingPreviousMonth = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteBudget(BudgetEntity budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: Text(
          'Eliminar presupuesto',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
          ),
        ),
        content: Text(
          '¿Seguro que quieres eliminar el presupuesto de "${budget.categoryName}"? Esta acción no se puede deshacer.',
          style: GoogleFonts.manrope(color: AppTheme.onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: GoogleFonts.manrope()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.expense,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _deleteBudget(budget.id);
      await _loadBudgets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Presupuesto eliminado.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Delete budget error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar el presupuesto.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  String _monthLabel(DateTime date) {
    return AppFormatters.formatMonthYear(date);
  }

  List<BudgetEntity> get _visibleBudgets {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _budgets;
    return _budgets
        .where((b) => b.categoryName.toLowerCase().contains(q))
        .toList();
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

    final totalBalance = totalLimit - totalSpent;
    final isMonthExceeded = totalBalance < 0;

    final exceededCount = _budgets.where((budget) => budget.isExceeded).length;
    final riskCount = _budgets.where((budget) {
      return !budget.isExceeded && budget.progress >= 0.8;
    }).length;
    final healthyCount = _budgets.where((budget) {
      return budget.progress < 0.8;
    }).length;

    final monthProgress = totalLimit > 0 ? (totalSpent / totalLimit) : 0.0;
    final headlineColor = isMonthExceeded ? AppTheme.expense : AppTheme.primary;

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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            fontWeight: FontWeight.w800,
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
                  Text(
                    isMonthExceeded
                        ? 'Vas ${_formatCurrency(totalBalance.abs())} por encima del límite total del mes.'
                        : 'Te quedan ${_formatCurrency(totalBalance)} dentro del límite total del mes.',
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
                      value: monthProgress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(headlineColor),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _BudgetMetric(
                          label: 'Límite total',
                          value: totalLimit,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BudgetMetric(
                          label: 'Consumido',
                          value: totalSpent,
                          color: AppTheme.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _BudgetStatusMetric(
                          label: 'Bien',
                          value: healthyCount,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BudgetStatusMetric(
                          label: 'En riesgo',
                          value: riskCount,
                          color: AppTheme.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BudgetStatusMetric(
                          label: 'Excedidos',
                          value: exceededCount,
                          color: AppTheme.expense,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Buscar por categoría',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Limpiar búsqueda',
                      ),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
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
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
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
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Puedes crear tus categorías principales o copiar la base del mes anterior para avanzar más rápido.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        height: 1.35,
                        color: AppTheme.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isCopyingPreviousMonth
                          ? null
                          : _copyBudgetsFromPreviousMonth,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isCopyingPreviousMonth
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.content_copy_rounded),
                      label: Text(
                        _isCopyingPreviousMonth
                            ? 'Copiando...'
                            : 'Copiar mes anterior',
                      ),
                    ),
                  ],
                ),
              )
            else if (_visibleBudgets.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 36,
                      color: AppTheme.onSurfaceMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin resultados para tu búsqueda.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._visibleBudgets.map(
                (budget) {
                  final progress = budget.progress.clamp(0.0, 1.2);
                  final displayColor =
                      budget.isExceeded ? AppTheme.expense : budget.color;

                  final statusLabel = budget.isExceeded
                      ? 'Límite superado'
                      : budget.progress >= 0.8
                          ? 'En zona de cuidado'
                          : 'Dentro del límite';

                  final statusColor = budget.isExceeded
                      ? AppTheme.expense
                      : budget.progress >= 0.8
                          ? AppTheme.warning
                          : AppTheme.onSurfaceMuted;

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
                                    : budget.progress >= 0.8
                                        ? Icons.timelapse_rounded
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
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    statusLabel,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
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
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                size: 18,
                                color: AppTheme.onSurfaceMuted,
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openEditBudgetSheet(budget);
                                } else if (value == 'delete') {
                                  _confirmDeleteBudget(budget);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: AppTheme.onSurface,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Editar',
                                        style: GoogleFonts.manrope(
                                          color: AppTheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppTheme.expense,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Eliminar',
                                        style: GoogleFonts.manrope(
                                          color: AppTheme.expense,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                          children: [
                            Expanded(
                              child: Text(
                                'Gastado: ${_formatCurrency(budget.spentAmount)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceMuted,
                                ),
                              ),
                            ),
                            Text(
                              '${(budget.progress * 100).clamp(0, 999).toStringAsFixed(0)}%',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: displayColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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
        borderRadius: BorderRadius.circular(16),
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

class _BudgetStatusMetric extends StatelessWidget {
  const _BudgetStatusMetric({
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
          color: color.withValues(alpha: 0.18),
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
