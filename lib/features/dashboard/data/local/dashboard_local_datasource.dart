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
  // Cambiamos la instanciación directa por una referencia recibida por constructor
  final TransactionLocalDataSource _transactionLocalDataSource;

  DashboardLocalDataSource(this._transactionLocalDataSource);

  Future<DashboardSummaryData> getSummary() async {
    // Obtenemos las transacciones desde la fuente local compartida
    final transactions = await _transactionLocalDataSource.getTransactions();

    // ✅ Cálculo eficiente en una sola pasada (O(n))
    double income = 0;
    double expense = 0;

    for (final t in transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    // ✅ Lógica de ordenamiento y selección de recientes
    // Nota: Si getTransactions ya viene ordenado por fecha DESC de la DB,
    // podrías ahorrarte el .sort() aquí para mejorar el rendimiento.
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
