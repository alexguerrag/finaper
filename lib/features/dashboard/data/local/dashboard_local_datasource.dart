import '../../../transactions/data/local/transaction_local_datasource.dart';
import '../../../transactions/data/models/transaction_model.dart';

class DashboardSummaryData {
  const DashboardSummaryData({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.recentTransactions,
  });

  final double balance;
  final double totalIncome;
  final double totalExpense;
  final List<TransactionModel> recentTransactions;
}

class DashboardLocalDataSource {
  const DashboardLocalDataSource(this._transactionLocalDataSource);

  final TransactionLocalDataSource _transactionLocalDataSource;

  Future<DashboardSummaryData> getSummary() async {
    final transactions = await _transactionLocalDataSource.getTransactions();

    double income = 0;
    double expense = 0;

    for (final transaction in transactions) {
      if (transaction.isIncome) {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
      }
    }

    final sorted = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return DashboardSummaryData(
      balance: income - expense,
      totalIncome: income,
      totalExpense: expense,
      recentTransactions: sorted.take(5).toList(),
    );
  }
}
