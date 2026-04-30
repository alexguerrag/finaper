class CashFlowSummary {
  const CashFlowSummary({
    required this.count,
    required this.total,
    required this.dailyAverage,
    required this.perTransactionAverage,
  });

  final int count;
  final double total;
  final double dailyAverage;
  final double perTransactionAverage;
}

class CashFlowEntity {
  const CashFlowEntity({
    required this.income,
    required this.expense,
    required this.daysInPeriod,
  });

  final CashFlowSummary income;
  final CashFlowSummary expense;
  final int daysInPeriod;

  double get netFlow => income.total - expense.total;
}
