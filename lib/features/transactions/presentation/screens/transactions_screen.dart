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
          content: Text(
            'No se pudieron cargar las transacciones.',
            style: GoogleFonts.manrope(),
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

  Future<void> _confirmDeleteTransaction(TransactionModel transaction) async {
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
      await _deleteTransaction(transaction.id ?? '');
      await refreshTransactions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transacción eliminada correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Delete transaction error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar la transacción.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  List<TransactionModel> get _filteredTransactions {
    var items = _transactions;

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
            item.note.toLowerCase().contains(query);
      }).toList();
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Map<String, List<TransactionModel>> get _groupedTransactions {
    final grouped = <String, List<TransactionModel>>{};
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));

    for (final transaction in _filteredTransactions) {
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

  String _formatSignedAmount({
    required double value,
    required bool isIncome,
  }) {
    final formatted = AppFormatters.formatCurrency(value.abs());
    return '${isIncome ? '+' : '-'}$formatted';
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = _totalIncome;
    final totalExpense = _totalExpense;
    final net = totalIncome - totalExpense;
    final grouped = _groupedTransactions;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransactionSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: refreshTransactions,
                child: ListView(
                  padding: const EdgeInsets.all(16),
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
                          child: Text(
                            'Transacciones',
                            style: GoogleFonts.manrope(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar transacción',
                        prefixIcon: const Icon(Icons.search_rounded),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _FilterChip(
                          label: 'Todas',
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
                          selected: _filter == _TransactionFilter.expense,
                          onTap: () {
                            setState(() {
                              _filter = _TransactionFilter.expense;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
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
                              label: 'Neto',
                              value: net,
                              color:
                                  net >= 0 ? AppTheme.income : AppTheme.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (grouped.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          'No hay transacciones para este filtro.',
                          style: GoogleFonts.manrope(
                            color: AppTheme.onSurfaceMuted,
                          ),
                        ),
                      )
                    else
                      ...grouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurfaceMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...entry.value.map(
                              (item) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color:
                                            item.color!.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        item.isIncome
                                            ? Icons.arrow_downward_rounded
                                            : Icons.arrow_upward_rounded,
                                        color: item.color,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          _openEditTransactionSheet(item);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.description,
                                                style: GoogleFonts.manrope(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.category,
                                                style: GoogleFonts.manrope(
                                                  fontSize: 12,
                                                  color:
                                                      AppTheme.onSurfaceMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatSignedAmount(
                                            value: item.amount,
                                            isIncome: item.isIncome,
                                          ),
                                          style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.w800,
                                            color: item.isIncome
                                                ? AppTheme.income
                                                : AppTheme.expense,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        PopupMenuButton<_TransactionAction>(
                                          tooltip: 'Acciones',
                                          color: AppTheme.surfaceElevated,
                                          icon: const Icon(
                                            Icons.more_vert_rounded,
                                            color: AppTheme.onSurfaceMuted,
                                          ),
                                          onSelected: (action) {
                                            switch (action) {
                                              case _TransactionAction.edit:
                                                _openEditTransactionSheet(item);
                                                break;
                                              case _TransactionAction.delete:
                                                _confirmDeleteTransaction(item);
                                                break;
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem<_TransactionAction>(
                                              value: _TransactionAction.edit,
                                              child: Text(
                                                'Editar',
                                                style: GoogleFonts.manrope(
                                                  color: AppTheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            PopupMenuItem<_TransactionAction>(
                                              value: _TransactionAction.delete,
                                              child: Text(
                                                'Eliminar',
                                                style: GoogleFonts.manrope(
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
            color: AppTheme.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$prefix$formatted',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
