// C:\dev\projects\finaper\lib\features\dashboard\data\local\dashboard_local_datasource.dart
import '../../../transactions/data/local/transaction_local_datasource.dart';
import '../../../transactions/data/models/transaction_model.dart';

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

    // ✅ Manejo seguro null-safety
    final totalIncome = transactions
        .where((t) => t.isIncome == true)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalExpense = transactions
        .where((t) => t.isIncome == false)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final balance = totalIncome - totalExpense;

    // ✅ Orden correcto por fecha (más recientes primero)
    final sorted = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final recentTransactions = sorted.take(5).toList();

    return DashboardSummaryData(
      balance: balance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      recentTransactions: recentTransactions,
    );
  }
}
