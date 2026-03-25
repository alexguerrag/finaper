import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/di/app_services.dart';
import '../../../../core/enums/recurrence_frequency.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/usecases/create_recurring_transaction.dart';
import '../../domain/usecases/get_recurring_transactions.dart';
import '../../domain/usecases/sync_due_recurring_transactions.dart';
import '../../domain/usecases/update_recurring_transaction.dart';
import '../widgets/add_recurring_transaction_sheet.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  late final GetRecurringTransactions _getRecurringTransactions;
  late final CreateRecurringTransaction _createRecurringTransaction;
  late final UpdateRecurringTransaction _updateRecurringTransaction;
  late final SyncDueRecurringTransactions _syncDueRecurringTransactions;

  bool _isLoading = true;
  _RecurringFilter _filter = _RecurringFilter.active;
  List<RecurringTransactionEntity> _items = <RecurringTransactionEntity>[];

  @override
  void initState() {
    super.initState();
    _getRecurringTransactions = AppServices.instance.getRecurringTransactions;
    _createRecurringTransaction =
        AppServices.instance.createRecurringTransaction;
    _updateRecurringTransaction =
        AppServices.instance.updateRecurringTransaction;
    _syncDueRecurringTransactions =
        AppServices.instance.syncDueRecurringTransactions;
    _loadRecurringTransactions();
  }

  Future<void> _loadRecurringTransactions() async {
    try {
      final items = await _getRecurringTransactions(includeInactive: true);

      if (!mounted) return;

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('RecurringTransactionsScreen load error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron cargar las recurrentes.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _openAddSheet() async {
    final result = await showModalBottomSheet<RecurringTransactionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddRecurringTransactionSheet(),
    );

    if (result == null) return;

    try {
      await _createRecurringTransaction(result);
      await _loadRecurringTransactions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recurrente creada correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Create recurring transaction error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo crear la recurrente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _toggleActive(
    RecurringTransactionEntity recurring,
    bool isActive,
  ) async {
    try {
      final updated = RecurringTransactionModel.fromEntity(recurring).copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      await _updateRecurringTransaction(updated);
      await _loadRecurringTransactions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive ? 'Recurrente activada.' : 'Recurrente desactivada.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Toggle recurring transaction error: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  Future<void> _processDueNow() async {
    try {
      final generated = await _syncDueRecurringTransactions();
      await _loadRecurringTransactions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            generated == 0
                ? 'No había recurrentes vencidas para procesar.'
                : 'Se generaron $generated transacciones.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Process due recurring error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron procesar las recurrentes.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  List<RecurringTransactionEntity> get _filteredItems {
    switch (_filter) {
      case _RecurringFilter.active:
        return _items.where((item) => item.isActive).toList();
      case _RecurringFilter.inactive:
        return _items.where((item) => !item.isActive).toList();
      case _RecurringFilter.all:
        return _items;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _frequencyLabel(RecurringTransactionEntity item) {
    final every = item.intervalValue == 1 ? '' : 'cada ${item.intervalValue} ';
    switch (item.frequency.label) {
      case 'Diaria':
        return item.intervalValue == 1 ? 'Diaria' : '${every}días';
      case 'Semanal':
        return item.intervalValue == 1 ? 'Semanal' : '${every}semanas';
      case 'Mensual':
        return item.intervalValue == 1 ? 'Mensual' : '${every}meses';
      case 'Anual':
        return item.intervalValue == 1 ? 'Anual' : '${every}años';
      default:
        return item.frequency.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Recurrentes',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _processDueNow,
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Procesar vencidas',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecurringTransactions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Gestiona movimientos automáticos como suscripciones, alquileres o salarios.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _RecurringFilterChip(
                  label: 'Activas',
                  selected: _filter == _RecurringFilter.active,
                  onTap: () {
                    setState(() {
                      _filter = _RecurringFilter.active;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _RecurringFilterChip(
                  label: 'Inactivas',
                  selected: _filter == _RecurringFilter.inactive,
                  onTap: () {
                    setState(() {
                      _filter = _RecurringFilter.inactive;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _RecurringFilterChip(
                  label: 'Todas',
                  selected: _filter == _RecurringFilter.all,
                  onTap: () {
                    setState(() {
                      _filter = _RecurringFilter.all;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.repeat_rounded,
                      size: 36,
                      color: AppTheme.onSurfaceMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Todavía no hay recurrentes en este filtro.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Crea una para automatizar tus movimientos repetitivos.',
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
              ...items.map(
                (item) => Container(
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
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              item.isIncome
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: item.color,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.description,
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.categoryName} · ${item.accountName}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppTheme.onSurfaceMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: item.isActive,
                            onChanged: (value) {
                              _toggleActive(item, value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.isIncome
                                      ? '+\$${item.amount.toStringAsFixed(2)}'
                                      : '-\$${item.amount.toStringAsFixed(2)}',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w800,
                                    color: item.isIncome
                                        ? AppTheme.income
                                        : AppTheme.expense,
                                  ),
                                ),
                                Text(
                                  _frequencyLabel(item),
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Próxima: ${_formatDate(item.nextRunDate)}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppTheme.onSurfaceMuted,
                                  ),
                                ),
                                Text(
                                  item.lastGeneratedDate == null
                                      ? 'Sin generar aún'
                                      : 'Última: ${_formatDate(item.lastGeneratedDate!)}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppTheme.onSurfaceMuted,
                                  ),
                                ),
                              ],
                            ),
                            if (item.endDate != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Finaliza: ${_formatDate(item.endDate!)}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: AppTheme.onSurfaceMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _RecurringFilter {
  active,
  inactive,
  all,
}

class _RecurringFilterChip extends StatelessWidget {
  const _RecurringFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.onSurface,
          ),
        ),
      ),
    );
  }
}

extension on RecurringTransactionModel {
  RecurringTransactionModel copyWith({
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return RecurringTransactionModel(
      id: id,
      accountId: accountId,
      accountName: accountName,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      amount: amount,
      isIncome: isIncome,
      note: note,
      color: color.withValues(alpha: 1.0),
      frequency: frequency,
      intervalValue: intervalValue,
      startDate: startDate,
      endDate: endDate,
      nextRunDate: nextRunDate,
      lastGeneratedDate: lastGeneratedDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
