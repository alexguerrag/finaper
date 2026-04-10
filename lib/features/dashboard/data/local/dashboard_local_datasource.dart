import '../../../../core/formatters/app_formatters.dart';
import '../../../transactions/data/local/transaction_local_datasource.dart';
import '../../../transactions/data/models/transaction_model.dart';

class DashboardExpenseCategorySummary {
  const DashboardExpenseCategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.colorValue,
  });

  final String categoryId;
  final String categoryName;
  final double amount;
  final double percentage;
  final int? colorValue;
}

class DashboardSummaryData {
  const DashboardSummaryData({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.recentTransactions,
    required this.monthIncome,
    required this.monthExpense,
    required this.monthNetFlow,
    required this.monthLabel,
    required this.topExpenseCategories,
    required this.hasTransactionsInMonth,
  });

  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final List<TransactionModel> recentTransactions;

  final double monthIncome;
  final double monthExpense;
  final double monthNetFlow;
  final String monthLabel;
  final List<DashboardExpenseCategorySummary> topExpenseCategories;
  final bool hasTransactionsInMonth;
}

class DashboardLocalDataSource {
  const DashboardLocalDataSource(this._transactionLocalDataSource);

  final TransactionLocalDataSource _transactionLocalDataSource;

  Future<DashboardSummaryData> getSummary({
    DateTime? month,
  }) async {
    final transactions = await _transactionLocalDataSource.getTransactions();

    double totalIncome = 0;
    double totalExpense = 0;

    for (final transaction in transactions) {
      if (transaction.isIncome) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    final sorted = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final selectedMonth = _monthStart(month ?? DateTime.now());
    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    double monthIncome = 0;
    double monthExpense = 0;

    final monthTransactions = <TransactionModel>[];
    final Map<String, _ExpenseCategoryAccumulator> expenseByCategory = {};

    for (final transaction in sorted) {
      final date = transaction.date;
      final isInSelectedMonth =
          !date.isBefore(selectedMonth) && date.isBefore(nextMonth);

      if (!isInSelectedMonth) {
        continue;
      }

      monthTransactions.add(transaction);

      if (transaction.isIncome) {
        monthIncome += transaction.amount;
        continue;
      }

      monthExpense += transaction.amount;

      final existing = expenseByCategory[transaction.categoryId];
      if (existing == null) {
        expenseByCategory[transaction.categoryId] = _ExpenseCategoryAccumulator(
          categoryId: transaction.categoryId,
          categoryName: transaction.category,
          amount: transaction.amount,
          colorValue: transaction.color?.toARGB32(),
        );
      } else {
        expenseByCategory[transaction.categoryId] = existing.copyWith(
          amount: existing.amount + transaction.amount,
          colorValue: existing.colorValue ?? transaction.color?.toARGB32(),
        );
      }
    }

    final topExpenseCategories = expenseByCategory.values
        .map(
          (item) => DashboardExpenseCategorySummary(
            categoryId: item.categoryId,
            categoryName: item.categoryName,
            amount: item.amount,
            percentage: monthExpense > 0 ? item.amount / monthExpense : 0,
            colorValue: item.colorValue,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return DashboardSummaryData(
      totalBalance: totalIncome - totalExpense,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      recentTransactions: monthTransactions.take(5).toList(),
      monthIncome: monthIncome,
      monthExpense: monthExpense,
      monthNetFlow: monthIncome - monthExpense,
      monthLabel: AppFormatters.formatMonthYearWith(
        value: selectedMonth,
        localeCode: 'es_CL',
      ),
      topExpenseCategories: topExpenseCategories.take(4).toList(),
      hasTransactionsInMonth: monthTransactions.isNotEmpty,
    );
  }

  DateTime _monthStart(DateTime value) {
    return DateTime(value.year, value.month, 1);
  }
}

class _ExpenseCategoryAccumulator {
  const _ExpenseCategoryAccumulator({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.colorValue,
  });

  final String categoryId;
  final String categoryName;
  final double amount;
  final int? colorValue;

  _ExpenseCategoryAccumulator copyWith({
    double? amount,
    int? colorValue,
  }) {
    return _ExpenseCategoryAccumulator(
      categoryId: categoryId,
      categoryName: categoryName,
      amount: amount ?? this.amount,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
