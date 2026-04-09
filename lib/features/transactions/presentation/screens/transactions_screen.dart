import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transaction_model.dart';
import '../../di/transactions_registry.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/get_all_transactions.dart';
import '../../domain/usecases/update_transaction.dart';
import '../widgets/transaction_details_sheet.dart';
import '../widgets/transaction_filters_sheet.dart';
import 'add_transaction_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  TransactionsScreenState createState() => TransactionsScreenState();
}

class TransactionsScreenState extends State<TransactionsScreen> {
  late final GetAllTransactions _getAllTransactions;
  late final AddTransaction _addTransaction;
  late final UpdateTransaction _updateTransaction;
  late final DeleteTransaction _deleteTransaction;

  bool _isLoading = true;
  String _searchQuery = '';
  _TransactionFilter _filter = _TransactionFilter.all;

  final TextEditingController _searchController = TextEditingController();

  List<TransactionModel> _transactions = <TransactionModel>[];

  TransactionListFilterState _listFilterState =
      const TransactionListFilterState(
    dateFilter: TransactionDateFilterOption.all,
    sortOption: TransactionSortOption.newestFirst,
  );

  @override
  void initState() {
    super.initState();
    _getAllTransactions = TransactionsRegistry.module.getAllTransactions;
    _addTransaction = TransactionsRegistry.module.addTransaction;
    _updateTransaction = TransactionsRegistry.module.updateTransaction;
    _deleteTransaction = TransactionsRegistry.module.deleteTransaction;
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> refreshTransactions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    await _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final result = await _getAllTransactions();

      if (!mounted) return;

      setState(() {
        _transactions =
            result.map((e) => TransactionModel.fromEntity(e)).toList();
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('TransactionsScreen load error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'No se pudieron cargar las transacciones.',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openAddTransactionSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(
        onAdd: (transaction) async {
          await _addTransaction(transaction);
          await refreshTransactions();
        },
      ),
    );
  }

  Future<void> _openEditTransactionSheet(TransactionModel transaction) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(
        initialTransaction: transaction,
        onAdd: (updatedTransaction) async {
          await _updateTransaction(updatedTransaction);
          await refreshTransactions();
        },
      ),
    );
  }

  Future<void> _openTransactionDetails(TransactionModel transaction) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailsSheet(
        transaction: transaction,
        onEdit: () {
          Navigator.of(context).pop();
          _openEditTransactionSheet(transaction);
        },
        onDelete: () {
          Navigator.of(context).pop();
          _confirmDeleteTransaction(transaction);
        },
        onDuplicate: () {
          Navigator.of(context).pop();
          _duplicateTransaction(transaction);
        },
      ),
    );
  }

  Future<void> _openFiltersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TransactionFiltersSheet(
        initialState: _listFilterState,
        onApply: (state) {
          setState(() {
            _listFilterState = state;
          });
        },
      ),
    );
  }

  Future<void> _duplicateTransaction(TransactionModel transaction) async {
    try {
      final duplicated = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        accountId: transaction.accountId,
        accountName: transaction.accountName,
        description: transaction.description,
        categoryId: transaction.categoryId,
        category: transaction.category,
        amount: transaction.amount,
        isIncome: transaction.isIncome,
        date: DateTime.now(),
        note: transaction.note,
        color: transaction.color,
      );

      await _addTransaction(duplicated);
      await refreshTransactions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Transacción duplicada correctamente.',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Duplicate transaction error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'No se pudo duplicar la transacción.',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteTransaction(TransactionModel transaction) async {
    final transactionId = transaction.id;
    if (transactionId == null || transactionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'La transacción no tiene un identificador válido.',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          title: Text(
            'Eliminar transacción',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          content: Text(
            '¿Seguro que quieres eliminar "${transaction.description}"?',
            style: GoogleFonts.manrope(
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Cancelar',
                style: GoogleFonts.manrope(),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.expense,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Eliminar',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _deleteTransaction(transactionId);
      await refreshTransactions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Transacción eliminada correctamente.',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Delete transaction error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'No se pudo eliminar la transacción.',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filter = _TransactionFilter.all;
      _listFilterState = const TransactionListFilterState(
        dateFilter: TransactionDateFilterOption.all,
        sortOption: TransactionSortOption.newestFirst,
      );
    });
  }

  List<TransactionModel> get _visibleTransactions {
    var items = List<TransactionModel>.from(_transactions);

    if (_filter == _TransactionFilter.income) {
      items = items.where((item) => item.isIncome).toList();
    } else if (_filter == _TransactionFilter.expense) {
      items = items.where((item) => !item.isIncome).toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((item) {
        return item.description.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query) ||
            item.accountName.toLowerCase().contains(query) ||
            item.note.toLowerCase().contains(query);
      }).toList();
    }

    items = _applyDateFilter(items);
    items = _applySort(items);

    return items;
  }

  List<TransactionModel> _applyDateFilter(List<TransactionModel> items) {
    final option = _listFilterState.dateFilter;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (option) {
      case TransactionDateFilterOption.all:
        return items;
      case TransactionDateFilterOption.last7Days:
        final start = today.subtract(const Duration(days: 6));
        return items.where((item) => !_isBeforeDate(item.date, start)).toList();
      case TransactionDateFilterOption.last30Days:
        final start = today.subtract(const Duration(days: 29));
        return items.where((item) => !_isBeforeDate(item.date, start)).toList();
      case TransactionDateFilterOption.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return items.where((item) => !_isBeforeDate(item.date, start)).toList();
      case TransactionDateFilterOption.custom:
        final range = _listFilterState.customRange;
        if (range == null) return items;
        final start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final end = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
          23,
          59,
          59,
        );
        return items
            .where(
              (item) => !item.date.isBefore(start) && !item.date.isAfter(end),
            )
            .toList();
    }
  }

  List<TransactionModel> _applySort(List<TransactionModel> items) {
    final sorted = List<TransactionModel>.from(items);

    switch (_listFilterState.sortOption) {
      case TransactionSortOption.newestFirst:
        sorted.sort((a, b) => b.date.compareTo(a.date));
        break;
      case TransactionSortOption.oldestFirst:
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case TransactionSortOption.highestAmount:
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case TransactionSortOption.lowestAmount:
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return sorted;
  }

  bool _isBeforeDate(DateTime value, DateTime reference) {
    final normalized = DateTime(value.year, value.month, value.day);
    return normalized.isBefore(reference);
  }

  Map<String, List<TransactionModel>> get _groupedTransactions {
    final grouped = <String, List<TransactionModel>>{};
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));

    for (final transaction in _visibleTransactions) {
      final key = _dateKey(transaction.date);

      String label;
      if (key == todayKey) {
        label = 'Hoy';
      } else if (key == yesterdayKey) {
        label = 'Ayer';
      } else {
        label = AppFormatters.formatShortDate(transaction.date);
      }

      grouped.putIfAbsent(label, () => <TransactionModel>[]).add(transaction);
    }

    return grouped;
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  double get _totalIncome => _transactions
      .where((e) => e.isIncome)
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get _totalExpense => _transactions
      .where((e) => !e.isIncome)
      .fold<double>(0, (sum, e) => sum + e.amount);

  int get _incomeCount => _transactions.where((e) => e.isIncome).length;

  int get _expenseCount => _transactions.where((e) => !e.isIncome).length;

  double get _visibleIncome => _visibleTransactions
      .where((e) => e.isIncome)
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get _visibleExpense => _visibleTransactions
      .where((e) => !e.isIncome)
      .fold<double>(0, (sum, e) => sum + e.amount);

  String _formatSignedAmount({
    required double value,
    required bool isIncome,
  }) {
    final formatted = AppFormatters.formatCurrency(value.abs());
    return '${isIncome ? '+' : '-'}$formatted';
  }

  String _resultSummaryText(int count) {
    if (count == 0) {
      return 'No hay resultados para tu búsqueda actual';
    }

    if (count == 1) {
      return '1 transacción encontrada';
    }

    return '$count transacciones encontradas';
  }

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _filter != _TransactionFilter.all ||
      _listFilterState.dateFilter != TransactionDateFilterOption.all ||
      _listFilterState.sortOption != TransactionSortOption.newestFirst;

  bool get _hasActiveSearch => _searchQuery.trim().isNotEmpty;

  bool get _hasActiveDateFilter =>
      _listFilterState.dateFilter != TransactionDateFilterOption.all;

  bool get _hasActiveSort =>
      _listFilterState.sortOption != TransactionSortOption.newestFirst;

  bool get _shouldShowSummaryCard =>
      _transactions.isNotEmpty &&
      (!_hasActiveSearch || _filter == _TransactionFilter.all);

  String get _activeDateFilterLabel {
    switch (_listFilterState.dateFilter) {
      case TransactionDateFilterOption.all:
        return 'Todo';
      case TransactionDateFilterOption.last7Days:
        return '7 días';
      case TransactionDateFilterOption.last30Days:
        return '30 días';
      case TransactionDateFilterOption.thisMonth:
        return 'Este mes';
      case TransactionDateFilterOption.custom:
        final range = _listFilterState.customRange;
        if (range == null) return 'Personalizado';
        return '${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}';
    }
  }

  String get _activeSortLabel {
    switch (_listFilterState.sortOption) {
      case TransactionSortOption.newestFirst:
        return 'Más recientes';
      case TransactionSortOption.oldestFirst:
        return 'Más antiguas';
      case TransactionSortOption.highestAmount:
        return 'Mayor monto';
      case TransactionSortOption.lowestAmount:
        return 'Menor monto';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = _totalIncome;
    final totalExpense = _totalExpense;
    final net = totalIncome - totalExpense;
    final visibleIncome = _visibleIncome;
    final visibleExpense = _visibleExpense;
    final grouped = _groupedTransactions;
    final visibleTransactions = _visibleTransactions;
    final canPop = Navigator.of(context).canPop();
    final visibleCount = visibleTransactions.length;
    final summaryValue = _filter == _TransactionFilter.expense
        ? visibleExpense
        : _filter == _TransactionFilter.income
            ? visibleIncome
            : net;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransactionSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Nueva',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: refreshTransactions,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Row(
                      children: [
                        if (canPop) ...[
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: 'Volver',
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.04),
                              foregroundColor: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transacciones',
                                style: GoogleFonts.manrope(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _resultSummaryText(visibleCount),
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _openFiltersSheet,
                          tooltip: 'Filtrar y ordenar',
                          style: IconButton.styleFrom(
                            backgroundColor: _hasActiveFilters
                                ? AppTheme.primary.withValues(alpha: 0.16)
                                : Colors.white.withValues(alpha: 0.04),
                            foregroundColor: _hasActiveFilters
                                ? AppTheme.primary
                                : AppTheme.onSurface,
                          ),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Buscar por concepto, categoría, cuenta o nota',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: _clearSearch,
                                icon: const Icon(Icons.close_rounded),
                                tooltip: 'Limpiar búsqueda',
                              ),
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Todas',
                            count: _transactions.length,
                            selected: _filter == _TransactionFilter.all,
                            onTap: () {
                              setState(() {
                                _filter = _TransactionFilter.all;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Ingresos',
                            count: _incomeCount,
                            selected: _filter == _TransactionFilter.income,
                            onTap: () {
                              setState(() {
                                _filter = _TransactionFilter.income;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Gastos',
                            count: _expenseCount,
                            selected: _filter == _TransactionFilter.expense,
                            onTap: () {
                              setState(() {
                                _filter = _TransactionFilter.expense;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_hasActiveFilters) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_hasActiveDateFilter)
                            _ActiveFilterBadge(
                              label: 'Período: $_activeDateFilterLabel',
                            ),
                          if (_hasActiveSort)
                            _ActiveFilterBadge(
                              label: 'Orden: $_activeSortLabel',
                            ),
                          if (_hasActiveSearch)
                            const _ActiveFilterBadge(
                              label: 'Búsqueda activa',
                            ),
                        ],
                      ),
                    ],
                    if (_shouldShowSummaryCard) ...[
                      const SizedBox(height: 18),
                      _AdaptiveSummaryCard(
                        filter: _filter,
                        totalIncome: totalIncome,
                        totalExpense: totalExpense,
                        totalNet: net,
                        visibleCount: visibleCount,
                        summaryValue: summaryValue,
                        onClearFilters:
                            _hasActiveFilters ? _clearFilters : null,
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (grouped.isEmpty)
                      _EmptyTransactionsState(
                        hasActiveFilters: _hasActiveFilters,
                        onClearFilters: _clearFilters,
                        onAddTransaction: _openAddTransactionSheet,
                      )
                    else
                      ...grouped.entries.map((entry) {
                        final dayIncome = entry.value
                            .where((item) => item.isIncome)
                            .fold<double>(0, (sum, item) => sum + item.amount);
                        final dayExpense = entry.value
                            .where((item) => !item.isIncome)
                            .fold<double>(0, (sum, item) => sum + item.amount);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TransactionSectionHeader(
                              label: entry.key,
                              count: entry.value.length,
                              income: dayIncome,
                              expense: dayExpense,
                            ),
                            const SizedBox(height: 12),
                            ...entry.value.map(
                              (item) => _TransactionCard(
                                item: item,
                                signedAmountText: _formatSignedAmount(
                                  value: item.amount,
                                  isIncome: item.isIncome,
                                ),
                                onTap: () {
                                  _openTransactionDetails(item);
                                },
                                onEdit: () {
                                  _openEditTransactionSheet(item);
                                },
                                onDelete: () {
                                  _confirmDeleteTransaction(item);
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}

enum _TransactionFilter {
  all,
  income,
  expense,
}

enum _TransactionAction {
  edit,
  delete,
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.70)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppTheme.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterBadge extends StatelessWidget {
  const _ActiveFilterBadge({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.onSurface,
        ),
      ),
    );
  }
}

class _AdaptiveSummaryCard extends StatelessWidget {
  const _AdaptiveSummaryCard({
    required this.filter,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalNet,
    required this.visibleCount,
    required this.summaryValue,
    required this.onClearFilters,
  });

  final _TransactionFilter filter;
  final double totalIncome;
  final double totalExpense;
  final double totalNet;
  final int visibleCount;
  final double summaryValue;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (filter == _TransactionFilter.all) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Ingresos',
                    value: totalIncome,
                    color: AppTheme.income,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Gastos',
                    value: totalExpense,
                    color: AppTheme.expense,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Balance',
                    value: totalNet,
                    color: totalNet >= 0 ? AppTheme.income : AppTheme.expense,
                  ),
                ),
              ],
            ),
            if (onClearFilters != null) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(
                    'Limpiar filtros',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final isIncome = filter == _TransactionFilter.income;
    final title = isIncome ? 'Ingresos visibles' : 'Gastos visibles';
    final accentColor = isIncome ? AppTheme.income : AppTheme.expense;
    final subtitle = visibleCount == 1
        ? '1 movimiento en pantalla'
        : '$visibleCount movimientos en pantalla';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppFormatters.formatCurrency(summaryValue.abs()),
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onClearFilters != null)
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(
                'Limpiar',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final formatted = AppFormatters.formatCurrency(value.abs());
    final prefix = value < 0 ? '-' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$prefix$formatted',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TransactionSectionHeader extends StatelessWidget {
  const _TransactionSectionHeader({
    required this.label,
    required this.count,
    required this.income,
    required this.expense,
  });

  final String label;
  final int count;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count mov.',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ),
          if (income > 0) ...[
            const SizedBox(width: 10),
            Text(
              '+${AppFormatters.formatCurrency(income)}',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.income,
              ),
            ),
          ],
          if (expense > 0) ...[
            const SizedBox(width: 8),
            Text(
              '-${AppFormatters.formatCurrency(expense)}',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.expense,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.item,
    required this.signedAmountText,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionModel item;
  final String signedAmountText;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final note = item.note.trim();
    final hasNote = note.isNotEmpty;
    final amountColor = item.isIncome ? AppTheme.income : AppTheme.expense;
    final iconColor = item.color ?? amountColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item.isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaBadge(
                            icon: Icons.category_rounded,
                            label: item.category,
                          ),
                          _MetaBadge(
                            icon: Icons.account_balance_wallet_rounded,
                            label: item.accountName,
                          ),
                          _MetaBadge(
                            icon: Icons.calendar_today_rounded,
                            label: AppFormatters.formatShortDate(item.date),
                          ),
                        ],
                      ),
                      if (hasNote) ...[
                        const SizedBox(height: 10),
                        Text(
                          note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            height: 1.35,
                            color: AppTheme.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      signedAmountText,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    PopupMenuButton<_TransactionAction>(
                      tooltip: 'Acciones',
                      color: AppTheme.surfaceElevated,
                      padding: EdgeInsets.zero,
                      splashRadius: 18,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      icon: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: AppTheme.onSurfaceMuted,
                        ),
                      ),
                      onSelected: (action) {
                        switch (action) {
                          case _TransactionAction.edit:
                            onEdit();
                            break;
                          case _TransactionAction.delete:
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<_TransactionAction>(
                          value: _TransactionAction.edit,
                          child: Text(
                            'Editar',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                        PopupMenuItem<_TransactionAction>(
                          value: _TransactionAction.delete,
                          child: Text(
                            'Eliminar',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.expense,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppTheme.onSurfaceMuted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactionsState extends StatelessWidget {
  const _EmptyTransactionsState({
    required this.hasActiveFilters,
    required this.onClearFilters,
    required this.onAddTransaction,
  });

  final bool hasActiveFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters
                ? 'No encontramos movimientos'
                : 'Todavía no tienes transacciones',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilters
                ? 'Prueba con otros filtros o limpia la búsqueda actual.'
                : 'Comienza registrando tu primer ingreso o gasto.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              height: 1.35,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              if (hasActiveFilters)
                OutlinedButton.icon(
                  onPressed: onClearFilters,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(
                    'Limpiar filtros',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: onAddTransaction,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Nueva transacción',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
