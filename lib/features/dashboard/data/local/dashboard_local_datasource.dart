import '../../../transactions/data/local/transaction_local_datasource.dart';
import '../../../transactions/domain/models/transaction_model.dart';

class DashboardSummaryData {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final List<TransactionModel> recentTransactions;

  const DashboardSummaryData({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.recentTransactions,
  });
}

class DashboardLocalDataSource {
  final TransactionLocalDataSource _transactionLocalDataSource =
      TransactionLocalDataSource();

  Future<DashboardSummaryData> getSummary() async {
    final transactions = await _transactionLocalDataSource.getTransactions();

    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalExpense = transactions
        .where((t) => !t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final balance = totalIncome - totalExpense;

    final recentTransactions = transactions.take(5).toList();

    return DashboardSummaryData(
      balance: balance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      recentTransactions: recentTransactions,
    );
  }
}
