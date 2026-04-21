import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../accounts/di/accounts_registry.dart';
import '../../../accounts/domain/usecases/get_accounts.dart';
import '../../data/models/transaction_model.dart';
import '../../di/transactions_registry.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/delete_transaction_group.dart';
import '../../domain/usecases/get_all_transactions.dart';
import '../../domain/usecases/update_transaction.dart';
import '../controllers/transaction_list_controller.dart';
import '../widgets/transaction_details_sheet.dart';
import '../widgets/transaction_filters_sheet.dart';
import '../widgets/transaction_list_widgets.dart';
import 'account_transfer_screen.dart';
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
  late final DeleteTransactionGroup _deleteTransactionGroup;
  late final GetAccounts _getAccounts;
  late final TransactionListController _controller;

  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getAllTransactions = TransactionsRegistry.module.getAllTransactions;
    _addTransaction = TransactionsRegistry.module.addTransaction;
    _updateTransaction = TransactionsRegistry.module.updateTransaction;
    _deleteTransaction = TransactionsRegistry.module.deleteTransaction;
    _deleteTransactionGroup =
        TransactionsRegistry.module.deleteTransactionGroup;
    _getAccounts = AccountsRegistry.module.getAccounts;
    _controller = TransactionListController();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ── data loading ──────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    await Future.wait([_loadTransactions(), _loadAccounts()]);
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _getAccounts(includeArchived: false);
      if (!mounted) return;
      _controller.setAccounts(accounts);
    } catch (e, s) {
      debugPrint('TransactionsScreen load accounts error: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  Future<void> refreshTransactions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final result = await _getAllTransactions();
      if (!mounted) return;
      _controller
          .setTransactions(result.map(TransactionModel.fromEntity).toList());
      setState(() => _isLoading = false);
    } catch (e, s) {
      debugPrint('TransactionsScreen load error: $e');
      debugPrintStack(stackTrace: s);
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'No se pudieron cargar las transacciones.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  // ── UI actions ────────────────────────────────────────────────────────────

  Future<void> _openAddTransactionSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(
        onAdd: (t) async {
          await _addTransaction(t);
          await refreshTransactions();
        },
      ),
    );
  }

  Future<void> _openEditTransactionSheet(TransactionModel transaction) async {
    if (transaction.isTransfer) {
      final didUpdate = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AccountTransferScreen(
            initialTransferGroupId: transaction.transferGroupId,
            initialFromAccountId:
                transaction.entryType.storageValue == 'transfer_out'
                    ? transaction.accountId
                    : transaction.counterpartyAccountId,
            initialFromAccountName:
                transaction.entryType.storageValue == 'transfer_out'
                    ? transaction.accountName
                    : transaction.counterpartyAccountName,
            initialToAccountId:
                transaction.entryType.storageValue == 'transfer_in'
                    ? transaction.accountId
                    : transaction.counterpartyAccountId,
            initialToAccountName:
                transaction.entryType.storageValue == 'transfer_in'
                    ? transaction.accountName
                    : transaction.counterpartyAccountName,
            initialAmount: transaction.amount,
            initialDate: transaction.date,
            initialDescription: transaction.description,
            initialNote: transaction.note,
          ),
        ),
      );
      if (didUpdate == true) await refreshTransactions();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(
        initialTransaction: transaction,
        onAdd: (updated) async {
          await _updateTransaction(updated);
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
        initialState: _controller.advancedFilter,
        onApply: _controller.setAdvancedFilter,
      ),
    );
  }

  Future<void> _duplicateTransaction(TransactionModel transaction) async {
    try {
      final now = DateTime.now();
      final duplicated = TransactionModel(
        id: now.millisecondsSinceEpoch.toString(),
        accountId: transaction.accountId,
        accountName: transaction.accountName,
        description: transaction.description,
        categoryId: transaction.categoryId,
        category: transaction.category,
        amount: transaction.amount,
        isIncome: transaction.isIncome,
        date: now,
        createdAt: now,
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
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
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
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteTransaction(TransactionModel transaction) async {
    final transactionId = transaction.id;
    final transferGroupId = transaction.transferGroupId?.trim();

    if ((transactionId == null || transactionId.isEmpty) &&
        (transferGroupId == null || transferGroupId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'La transacción no tiene un identificador válido.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    final isTransfer = transaction.isTransfer;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: Text(
          isTransfer ? 'Eliminar transferencia' : 'Eliminar transacción',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
          ),
        ),
        content: Text(
          isTransfer
              ? '¿Seguro que quieres eliminar esta transferencia completa? Se eliminarán ambas patas del movimiento.'
              : '¿Seguro que quieres eliminar "${transaction.description}"?',
          style: GoogleFonts.manrope(color: AppTheme.onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancelar', style: GoogleFonts.manrope()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
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
      if (isTransfer) {
        await _deleteTransactionGroup(transferGroupId!);
      } else {
        await _deleteTransaction(transactionId!);
      }
      await refreshTransactions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            isTransfer
                ? 'Transferencia eliminada correctamente.'
                : 'Transacción eliminada correctamente.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
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
            isTransfer
                ? 'No se pudo eliminar la transferencia.'
                : 'No se pudo eliminar la transacción.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.setSearchQuery('');
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FloatingActionButton.extended(
          onPressed: _openAddTransactionSheet,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'Nueva',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final c = _controller;
                  final grouped = c.groupedTransactions;

                  return RefreshIndicator(
                    onRefresh: refreshTransactions,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
                      children: [
                        // ── header ──────────────────────────────────────────
                        Row(
                          children: [
                            if (canPop) ...[
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
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
                                    c.resultSummaryText,
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
                                backgroundColor: c.hasActiveFilters
                                    ? AppTheme.primary.withValues(alpha: 0.16)
                                    : Colors.white.withValues(alpha: 0.04),
                                foregroundColor: c.hasActiveFilters
                                    ? AppTheme.primary
                                    : AppTheme.onSurface,
                              ),
                              icon: const Icon(Icons.tune_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // ── search ───────────────────────────────────────────
                        TextField(
                          controller: _searchController,
                          onChanged: _controller.setSearchQuery,
                          decoration: InputDecoration(
                            hintText:
                                'Buscar por concepto, categoría, cuenta o nota',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: c.searchQuery.trim().isEmpty
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

                        // ── type filter chips ────────────────────────────────
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              TxTypeFilterChip(
                                label: 'Todas',
                                count: c.allTransactions.length,
                                selected:
                                    c.typeFilter == TransactionTypeFilter.all,
                                onTap: () => c
                                    .setTypeFilter(TransactionTypeFilter.all),
                              ),
                              const SizedBox(width: 8),
                              TxTypeFilterChip(
                                label: 'Ingresos',
                                count: c.incomeCount,
                                selected: c.typeFilter ==
                                    TransactionTypeFilter.income,
                                onTap: () => c.setTypeFilter(
                                    TransactionTypeFilter.income),
                              ),
                              const SizedBox(width: 8),
                              TxTypeFilterChip(
                                label: 'Gastos',
                                count: c.expenseCount,
                                selected: c.typeFilter ==
                                    TransactionTypeFilter.expense,
                                onTap: () => c.setTypeFilter(
                                    TransactionTypeFilter.expense),
                              ),
                            ],
                          ),
                        ),

                        // ── account filter chips ─────────────────────────────
                        if (c.accounts.length >= 2) ...[
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: c.accounts.map((account) {
                                final selected =
                                    c.selectedAccountId == account.id;
                                final count = c.allTransactions
                                    .where((t) => t.accountId == account.id)
                                    .length;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: TxTypeFilterChip(
                                    label: account.name,
                                    count: count,
                                    selected: selected,
                                    onTap: () => c.setSelectedAccount(
                                        selected ? null : account.id),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],

                        // ── active filter badges ─────────────────────────────
                        if (c.hasActiveFilters) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (c.hasActiveDateFilter)
                                TxActiveFilterBadge(
                                  label: 'Período: ${c.activeDateFilterLabel}',
                                ),
                              if (c.hasActiveSort)
                                TxActiveFilterBadge(
                                  label: 'Orden: ${c.activeSortLabel}',
                                ),
                              if (c.hasActiveSearch)
                                const TxActiveFilterBadge(
                                  label: 'Búsqueda activa',
                                ),
                            ],
                          ),
                        ],

                        // ── summary card ─────────────────────────────────────
                        if (c.shouldShowSummary) ...[
                          const SizedBox(height: 18),
                          TxAdaptiveSummaryCard(
                            filter: c.typeFilter,
                            totalIncome: c.totalIncome,
                            totalExpense: c.totalExpense,
                            totalNet: c.totalNet,
                            visibleCount: c.visibleTransactions.length,
                            summaryValue: c.summaryValue,
                            onClearFilters:
                                c.hasActiveFilters ? c.clearFilters : null,
                          ),
                        ],
                        const SizedBox(height: 24),

                        // ── list ─────────────────────────────────────────────
                        if (grouped.isEmpty)
                          TxEmptyState(
                            hasActiveFilters: c.hasActiveFilters,
                            onClearFilters: c.clearFilters,
                            onAddTransaction: _openAddTransactionSheet,
                          )
                        else
                          ...grouped.entries.map((entry) {
                            final dayIncome = entry.value
                                .where((e) => e.isIncome)
                                .fold(0.0, (s, e) => s + e.amount);
                            final dayExpense = entry.value
                                .where((e) => !e.isIncome)
                                .fold(0.0, (s, e) => s + e.amount);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TxSectionHeader(
                                  label: entry.key,
                                  count: entry.value.length,
                                  income: dayIncome,
                                  expense: dayExpense,
                                ),
                                const SizedBox(height: 12),
                                ...entry.value.map(
                                  (item) => TxCard(
                                    item: item,
                                    onTap: () =>
                                        _openTransactionDetails(item),
                                    onEdit: () =>
                                        _openEditTransactionSheet(item),
                                    onDelete: () =>
                                        _confirmDeleteTransaction(item),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
