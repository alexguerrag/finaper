import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/di/app_services.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/get_all_transactions.dart';
import 'add_transaction_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  TransactionTypeFilter _selectedFilter = TransactionTypeFilter.all;

  late List<TransactionModel> _transactions;
  late List<TransactionModel> _filteredTransactions;

  late GetAllTransactions getAllTransactions;
  late AddTransaction addTransaction;

  bool _isLoading = true;

  final List<TransactionModel> _seedData = [
    TransactionModel(
      id: '1',
      description: 'Salario mensual',
      category: 'Salario',
      amount: 4820.0,
      isIncome: true,
      date: DateTime(2026, 3, 20),
      note: '',
    ),
    TransactionModel(
      id: '2',
      description: 'Supermercado',
      category: 'Alimentación',
      amount: 156.8,
      isIncome: false,
      date: DateTime(2026, 3, 19),
      note: '',
    ),
    TransactionModel(
      id: '3',
      description: 'Netflix',
      category: 'Entretenimiento',
      amount: 28.5,
      isIncome: false,
      date: DateTime(2026, 3, 18),
      note: '',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _transactions = [];
    _filteredTransactions = [];
    _searchController.addListener(_applyFilters);

    getAllTransactions = AppServices.instance.getAllTransactions;
    addTransaction = AppServices.instance.addTransaction;

    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    try {
      final data = await getAllTransactions();

      if (!mounted) return;

      setState(() {
        _transactions =
            data.map((entity) => TransactionModel.fromEntity(entity)).toList();
        _filteredTransactions = List<TransactionModel>.from(_transactions);
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      debugPrint('Error loading transactions: $e');

      if (!mounted) return;

      setState(() {
        _transactions = List<TransactionModel>.from(_seedData);
        _filteredTransactions = List<TransactionModel>.from(_seedData);
        _isLoading = false;
      });
    }
  }

  Future<void> _addTransaction(TransactionModel transaction) async {
    try {
      await addTransaction(transaction);
      await _loadTransactions();
    } catch (e) {
      debugPrint('Error adding transaction: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la transacción.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  void _openAddTransactionSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(
        onAdd: _addTransaction,
      ),
    );
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredTransactions = _transactions.where((tx) {
        final matchesSearch = tx.description.toLowerCase().contains(query) ||
            tx.category.toLowerCase().contains(query) ||
            tx.note.toLowerCase().contains(query);

        final matchesType = _selectedFilter == TransactionTypeFilter.all ||
            (_selectedFilter == TransactionTypeFilter.income && tx.isIncome) ||
            (_selectedFilter == TransactionTypeFilter.expense && !tx.isIncome);

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  Map<String, List<TransactionModel>> _groupedTransactions() {
    final Map<String, List<TransactionModel>> grouped = {};

    for (final tx in _filteredTransactions) {
      final date = tx.date;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final txDate = DateTime(date.year, date.month, date.day);
      final difference = today.difference(txDate).inDays;

      String key;

      if (difference == 0) {
        key = 'Hoy';
      } else if (difference == 1) {
        key = 'Ayer';
      } else {
        key =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }

      grouped.putIfAbsent(key, () => <TransactionModel>[]);
      grouped[key]!.add(tx);
    }

    return grouped;
  }

  double get totalIncome => _filteredTransactions
      .where((transaction) => transaction.isIncome)
      .fold<double>(0.0, (sum, transaction) => sum + transaction.amount);

  double get totalExpense => _filteredTransactions
      .where((transaction) => !transaction.isIncome)
      .fold<double>(0.0, (sum, transaction) => sum + transaction.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransactionSheet,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      appBar: AppBar(
        title: Text(
          'Transacciones',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilters(),
                _buildSummary(),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar transacción',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _filterChip('Todas', TransactionTypeFilter.all),
              const SizedBox(width: 8),
              _filterChip('Ingresos', TransactionTypeFilter.income),
              const SizedBox(width: 8),
              _filterChip('Gastos', TransactionTypeFilter.expense),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, TransactionTypeFilter type) {
    final isSelected = _selectedFilter == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = type;
        });
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final net = totalIncome - totalExpense;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryItem('Ingresos', totalIncome, AppTheme.income),
          _summaryItem('Gastos', totalExpense, AppTheme.expense),
          _summaryItem(
            'Neto',
            net,
            net >= 0 ? AppTheme.income : AppTheme.expense,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${value.toStringAsFixed(0)}',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron transacciones',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
      );
    }

    final grouped = _groupedTransactions();
    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: keys.length,
      itemBuilder: (_, index) {
        final section = keys[index];
        final items = grouped[section]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                section,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            ),
            ...items.map((tx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: tx.isIncome
                          ? AppTheme.income.withValues(alpha: 0.2)
                          : AppTheme.expense.withValues(alpha: 0.2),
                      child: Icon(
                        tx.isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: tx.isIncome ? AppTheme.income : AppTheme.expense,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.description,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            tx.category,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      tx.isIncome
                          ? '+\$${tx.amount.toStringAsFixed(2)}'
                          : '-\$${tx.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: tx.isIncome ? AppTheme.income : AppTheme.expense,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
