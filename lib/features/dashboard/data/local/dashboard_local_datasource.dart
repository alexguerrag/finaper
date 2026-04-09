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
  final int colorValue;
}

class DashboardSummaryData {
  const DashboardSummaryData({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.recentTransactions,
    required this.currentMonthIncome,
    required this.currentMonthExpense,
    required this.currentMonthNetFlow,
    required this.currentMonthTransactionCount,
    required this.currentMonthLabel,
    required this.topExpenseCategories,
  });

  final double balance;
  final double totalIncome;
  final double totalExpense;
  final List<TransactionModel> recentTransactions;

  final double currentMonthIncome;
  final double currentMonthExpense;
  final double currentMonthNetFlow;
  final int currentMonthTransactionCount;
  final String currentMonthLabel;
  final List<DashboardExpenseCategorySummary> topExpenseCategories;
}

class DashboardLocalDataSource {
  const DashboardLocalDataSource(this._transactionLocalDataSource);

  final TransactionLocalDataSource _transactionLocalDataSource;

  Future<DashboardSummaryData> getSummary() async {
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

    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    double currentMonthIncome = 0;
    double currentMonthExpense = 0;
    int currentMonthTransactionCount = 0;

    final Map<String, _ExpenseCategoryAccumulator> expenseByCategory = {};

    for (final transaction in transactions) {
      final transactionDate = transaction.date;

      final isInCurrentMonth = !transactionDate.isBefore(currentMonthStart) &&
          transactionDate.isBefore(nextMonthStart);

      if (!isInCurrentMonth) {
        continue;
      }

      currentMonthTransactionCount++;

      if (transaction.isIncome) {
        currentMonthIncome += transaction.amount;
        continue;
      }

      currentMonthExpense += transaction.amount;

      final categoryId = transaction.categoryId;
      final existing = expenseByCategory[categoryId];

      if (existing == null) {
        expenseByCategory[categoryId] = _ExpenseCategoryAccumulator(
          categoryId: categoryId,
          categoryName: transaction.category,
          amount: transaction.amount,
          colorValue: transaction.color?.toARGB32(),
        );
      } else {
        expenseByCategory[categoryId] = existing.copyWith(
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
            percentage:
                currentMonthExpense > 0 ? item.amount / currentMonthExpense : 0,
            colorValue: item.colorValue ?? 0xFF000000,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return DashboardSummaryData(
      balance: totalIncome - totalExpense,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      recentTransactions: sorted.take(5).toList(),
      currentMonthIncome: currentMonthIncome,
      currentMonthExpense: currentMonthExpense,
      currentMonthNetFlow: currentMonthIncome - currentMonthExpense,
      currentMonthTransactionCount: currentMonthTransactionCount,
      currentMonthLabel: _buildCurrentMonthLabel(now),
      topExpenseCategories: topExpenseCategories.take(4).toList(),
    );
  }

  String _buildCurrentMonthLabel(DateTime now) {
    return AppFormatters.formatMonthYear(now);
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
