import '../../../transactions/data/local/transaction_local_datasource.dart';
import '../../../transactions/data/models/transaction_model.dart';

class DashboardSummaryData {
  const DashboardSummaryData({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.recentTransactions,
    required this.recentPeriodIncome,
    required this.recentPeriodExpense,
    required this.recentPeriodBalance,
    required this.recentPeriodTransactionCount,
    required this.recentPeriodLabel,
  });

  final double balance;
  final double totalIncome;
  final double totalExpense;
  final List<TransactionModel> recentTransactions;

  final double recentPeriodIncome;
  final double recentPeriodExpense;
  final double recentPeriodBalance;
  final int recentPeriodTransactionCount;
  final String recentPeriodLabel;
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
    final today = _dateOnly(now);
    final recentStart = today.subtract(const Duration(days: 29));

    double recentIncome = 0;
    double recentExpense = 0;
    int recentCount = 0;

    for (final transaction in transactions) {
      final transactionDate = _dateOnly(transaction.date);

      if (transactionDate.isBefore(recentStart) ||
          transactionDate.isAfter(today)) {
        continue;
      }

      recentCount++;

      if (transaction.isIncome) {
        recentIncome += transaction.amount;
      } else {
        recentExpense += transaction.amount;
      }
    }

    return DashboardSummaryData(
      balance: totalIncome - totalExpense,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      recentTransactions: sorted.take(5).toList(),
      recentPeriodIncome: recentIncome,
      recentPeriodExpense: recentExpense,
      recentPeriodBalance: recentIncome - recentExpense,
      recentPeriodTransactionCount: recentCount,
      recentPeriodLabel: 'Últimos 30 días',
    );
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
