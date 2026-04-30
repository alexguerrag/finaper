enum LedgerPeriod { days7, days30, thisMonth }

class LedgerCategoryRow {
  const LedgerCategoryRow({
    required this.categoryName,
    required this.amount,
    required this.count,
  });

  final String categoryName;
  final double amount;
  final int count;
}

class LedgerEntity {
  const LedgerEntity({
    required this.period,
    required this.totalIncome,
    required this.totalExpense,
    required this.incomeRows,
    required this.expenseRows,
  });

  final LedgerPeriod period;
  final double totalIncome;
  final double totalExpense;
  final List<LedgerCategoryRow> incomeRows;
  final List<LedgerCategoryRow> expenseRows;

  double get netFlow => totalIncome - totalExpense;
}
