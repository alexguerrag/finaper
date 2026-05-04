import 'package:flutter/material.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../accounts/di/accounts_registry.dart';
import '../../../accounts/domain/entities/account_entity.dart';
import '../../../accounts/domain/usecases/get_accounts.dart';
import '../../data/models/transaction_model.dart';
import '../../di/transactions_registry.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/delete_transaction_group.dart';
import '../../domain/usecases/get_all_transactions.dart';
import '../../domain/usecases/update_transaction.dart';
import '../widgets/transaction_filters_sheet.dart';

enum TransactionTypeFilter { all, income, expense }

class TransactionListController extends ChangeNotifier {
  // ── use cases (lazy — initialized on first loadAll()) ─────────────────────
  late final GetAllTransactions _getAllTransactions;
  late final AddTransaction _addTransaction;
  late final UpdateTransaction _updateTransaction;
  late final DeleteTransaction _deleteTransaction;
  late final DeleteTransactionGroup _deleteTransactionGroup;
  late final GetAccounts _getAccounts;
  bool _useCasesReady = false;

  // ── load state ────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _hasLoadError = false;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;

  void clearLoadError() => _hasLoadError = false;

  // ── raw data ──────────────────────────────────────────────────────────────
  List<TransactionModel> _allTransactions = [];
  List<AccountEntity> _accounts = [];

  // ── filter state ──────────────────────────────────────────────────────────
  String _searchQuery = '';
  TransactionTypeFilter _typeFilter = TransactionTypeFilter.all;
  String? _selectedAccountId;
  TransactionListFilterState _advancedFilter = const TransactionListFilterState(
    dateFilter: TransactionDateFilterOption.all,
    sortOption: TransactionSortOption.newestFirst,
  );

  // ── lazy cache ────────────────────────────────────────────────────────────
  List<TransactionModel>? _cachedVisible;
  Map<String, List<TransactionModel>>? _cachedGrouped;

  // ── public read-only accessors ────────────────────────────────────────────
  List<AccountEntity> get accounts => _accounts;
  List<TransactionModel> get allTransactions => _allTransactions;
  String get searchQuery => _searchQuery;
  TransactionTypeFilter get typeFilter => _typeFilter;
  String? get selectedAccountId => _selectedAccountId;
  TransactionListFilterState get advancedFilter => _advancedFilter;

  // ── computed: totals over raw data (unfiltered, transfers excluded) ──────
  double get totalIncome => _allTransactions
      .where((e) => e.isIncome && !e.isTransfer)
      .fold(0.0, (s, e) => s + e.amount);

  double get totalExpense => _allTransactions
      .where((e) => !e.isIncome && !e.isTransfer)
      .fold(0.0, (s, e) => s + e.amount);

  int get totalCount => _allTransactions.where((e) => !e.isTransfer).length;
  int get incomeCount =>
      _allTransactions.where((e) => e.isIncome && !e.isTransfer).length;
  int get expenseCount =>
      _allTransactions.where((e) => !e.isIncome && !e.isTransfer).length;

  // ── computed: cached visible + grouped ────────────────────────────────────
  List<TransactionModel> get visibleTransactions =>
      _cachedVisible ??= _computeVisible();

  Map<String, List<TransactionModel>> get groupedTransactions =>
      _cachedGrouped ??= _computeGrouped();

  double get visibleIncome => visibleTransactions
      .where((e) => e.isIncome && !e.isTransfer)
      .fold(0.0, (s, e) => s + e.amount);

  double get visibleExpense => visibleTransactions
      .where((e) => !e.isIncome && !e.isTransfer)
      .fold(0.0, (s, e) => s + e.amount);

  // ── filter state queries ──────────────────────────────────────────────────
  bool get hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _typeFilter != TransactionTypeFilter.all ||
      _selectedAccountId != null ||
      _advancedFilter.dateFilter != TransactionDateFilterOption.all ||
      _advancedFilter.sortOption != TransactionSortOption.newestFirst;

  bool get hasActiveSearch => _searchQuery.trim().isNotEmpty;

  bool get hasActiveDateFilter =>
      _advancedFilter.dateFilter != TransactionDateFilterOption.all;

  bool get hasActiveSort =>
      _advancedFilter.sortOption != TransactionSortOption.newestFirst;

  String get resultSummaryText {
    final count = visibleTransactions.length;
    if (count == 0) return 'No hay resultados para tu búsqueda actual';
    if (count == 1) return '1 transacción encontrada';
    return '$count transacciones encontradas';
  }

  double get totalNet => totalIncome - totalExpense;

  double get visibleNet => visibleIncome - visibleExpense;

  double get summaryValue {
    if (_typeFilter == TransactionTypeFilter.expense) return visibleExpense;
    if (_typeFilter == TransactionTypeFilter.income) return visibleIncome;
    return visibleNet;
  }

  bool get shouldShowSummary =>
      _allTransactions.isNotEmpty &&
      (!hasActiveSearch || _typeFilter == TransactionTypeFilter.all);

  String get activeDateFilterLabel {
    switch (_advancedFilter.dateFilter) {
      case TransactionDateFilterOption.all:
        return 'Todo';
      case TransactionDateFilterOption.last7Days:
        return '7 días';
      case TransactionDateFilterOption.last30Days:
        return '30 días';
      case TransactionDateFilterOption.thisMonth:
        return 'Este mes';
      case TransactionDateFilterOption.custom:
        final range = _advancedFilter.customRange;
        if (range == null) return 'Personalizado';
        return '${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}';
    }
  }

  String get activeSortLabel {
    switch (_advancedFilter.sortOption) {
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

  // ── data loading ──────────────────────────────────────────────────────────
  Future<void> loadAll() async {
    _initUseCases();
    _isLoading = true;
    _hasLoadError = false;
    _notify();
    await Future.wait([_fetchTransactions(), _fetchAccounts()]);
  }

  Future<void> refresh() async {
    _initUseCases();
    _isLoading = true;
    _notify();
    await _fetchTransactions();
  }

  Future<void> _fetchAccounts() async {
    try {
      final accounts = await _getAccounts(includeArchived: true);
      _accounts = accounts;
      _notify();
    } catch (e, s) {
      debugPrint('TransactionListController: load accounts error: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final result = await _getAllTransactions();
      _allTransactions = result.map(TransactionModel.fromEntity).toList();
      _invalidateCache();
      _isLoading = false;
      _notify();
    } catch (e, s) {
      debugPrint('TransactionListController: load transactions error: $e');
      debugPrintStack(stackTrace: s);
      _isLoading = false;
      _hasLoadError = true;
      _notify();
    }
  }

  // ── CRUD operations ───────────────────────────────────────────────────────
  Future<void> addTransaction(TransactionModel t) async {
    await _addTransaction(t);
    await refresh();
  }

  Future<void> updateTransaction(TransactionModel t) async {
    await _updateTransaction(t);
    await refresh();
  }

  Future<void> deleteTransaction(String id) async {
    await _deleteTransaction(id);
    await refresh();
  }

  Future<void> deleteTransactionGroup(String groupId) async {
    await _deleteTransactionGroup(groupId);
    await refresh();
  }

  Future<void> duplicateTransaction(TransactionModel source) async {
    final now = DateTime.now();
    final copy = TransactionModel(
      id: now.millisecondsSinceEpoch.toString(),
      accountId: source.accountId,
      accountName: source.accountName,
      description: source.description,
      categoryId: source.categoryId,
      category: source.category,
      amount: source.amount,
      isIncome: source.isIncome,
      date: now,
      createdAt: now,
      note: source.note,
      color: source.color,
    );
    await _addTransaction(copy);
    await refresh();
  }

  // ── filter mutations ──────────────────────────────────────────────────────
  void setTransactions(List<TransactionModel> transactions) {
    _allTransactions = transactions;
    _invalidateCache();
    notifyListeners();
  }

  void setAccounts(List<AccountEntity> accounts) {
    _accounts = accounts;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    _invalidateCache();
    notifyListeners();
  }

  void setTypeFilter(TransactionTypeFilter filter) {
    if (_typeFilter == filter) return;
    _typeFilter = filter;
    _invalidateCache();
    notifyListeners();
  }

  void setSelectedAccount(String? id) {
    if (_selectedAccountId == id) return;
    _selectedAccountId = id;
    _invalidateCache();
    notifyListeners();
  }

  void setAdvancedFilter(TransactionListFilterState state) {
    _advancedFilter = state;
    _invalidateCache();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _typeFilter = TransactionTypeFilter.all;
    _selectedAccountId = null;
    _advancedFilter = const TransactionListFilterState(
      dateFilter: TransactionDateFilterOption.all,
      sortOption: TransactionSortOption.newestFirst,
    );
    _invalidateCache();
    notifyListeners();
  }

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ── private helpers ───────────────────────────────────────────────────────
  void _initUseCases() {
    if (_useCasesReady) return;
    _getAllTransactions = TransactionsRegistry.module.getAllTransactions;
    _addTransaction = TransactionsRegistry.module.addTransaction;
    _updateTransaction = TransactionsRegistry.module.updateTransaction;
    _deleteTransaction = TransactionsRegistry.module.deleteTransaction;
    _deleteTransactionGroup =
        TransactionsRegistry.module.deleteTransactionGroup;
    _getAccounts = AccountsRegistry.module.getAccounts;
    _useCasesReady = true;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _invalidateCache() {
    _cachedVisible = null;
    _cachedGrouped = null;
  }

  List<TransactionModel> _computeVisible() {
    var items = _allTransactions.where((e) => !e.isTransfer).toList();

    if (_typeFilter == TransactionTypeFilter.income) {
      items = items.where((e) => e.isIncome).toList();
    } else if (_typeFilter == TransactionTypeFilter.expense) {
      items = items.where((e) => !e.isIncome).toList();
    }

    if (_selectedAccountId != null) {
      items = items.where((e) => e.accountId == _selectedAccountId).toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((e) {
        return e.description.toLowerCase().contains(query) ||
            e.category.toLowerCase().contains(query) ||
            e.accountName.toLowerCase().contains(query) ||
            e.note.toLowerCase().contains(query);
      }).toList();
    }

    items = _applyDateFilter(items);
    items = _applySort(items);
    return items;
  }

  List<TransactionModel> _applyDateFilter(List<TransactionModel> items) {
    final option = _advancedFilter.dateFilter;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (option) {
      case TransactionDateFilterOption.all:
        return items;
      case TransactionDateFilterOption.last7Days:
        final start = today.subtract(const Duration(days: 6));
        return items.where((e) => !_isBeforeDate(e.date, start)).toList();
      case TransactionDateFilterOption.last30Days:
        final start = today.subtract(const Duration(days: 29));
        return items.where((e) => !_isBeforeDate(e.date, start)).toList();
      case TransactionDateFilterOption.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return items.where((e) => !_isBeforeDate(e.date, start)).toList();
      case TransactionDateFilterOption.custom:
        final range = _advancedFilter.customRange;
        if (range == null) return items;
        final start =
            DateTime(range.start.year, range.start.month, range.start.day);
        final end = DateTime(
            range.end.year, range.end.month, range.end.day, 23, 59, 59);
        return items
            .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
            .toList();
    }
  }

  List<TransactionModel> _applySort(List<TransactionModel> items) {
    final sorted = List<TransactionModel>.from(items);
    switch (_advancedFilter.sortOption) {
      case TransactionSortOption.newestFirst:
        sorted.sort((a, b) {
          final cmp = b.date.compareTo(a.date);
          return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
        });
      case TransactionSortOption.oldestFirst:
        sorted.sort((a, b) {
          final cmp = a.date.compareTo(b.date);
          return cmp != 0 ? cmp : a.createdAt.compareTo(b.createdAt);
        });
      case TransactionSortOption.highestAmount:
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
      case TransactionSortOption.lowestAmount:
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
    }
    return sorted;
  }

  bool _isBeforeDate(DateTime value, DateTime reference) {
    final normalized = DateTime(value.year, value.month, value.day);
    return normalized.isBefore(reference);
  }

  Map<String, List<TransactionModel>> _computeGrouped() {
    final grouped = <String, List<TransactionModel>>{};
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));

    for (final t in visibleTransactions) {
      final key = _dateKey(t.date);
      final String label;
      if (key == todayKey) {
        label = 'Hoy';
      } else if (key == yesterdayKey) {
        label = 'Ayer';
      } else {
        label = AppFormatters.formatShortDate(t.date);
      }
      grouped.putIfAbsent(label, () => []).add(t);
    }
    return grouped;
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
