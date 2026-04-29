enum ProjectionReliability {
  low, // daysElapsed < 7 — too few data points
  medium, // 7 <= daysElapsed < 20
  high, // daysElapsed >= 20
}

class BudgetRisk {
  const BudgetRisk({
    required this.categoryName,
    required this.amountLimit,
    required this.projectedSpend,
    required this.overagePercent,
  });

  final String categoryName;
  final double amountLimit;
  final double projectedSpend;
  final double overagePercent; // (projected - limit) / limit * 100
}

class MonthProjectionEntity {
  const MonthProjectionEntity({
    required this.currentExpense,
    required this.projectedExpense,
    required this.currentIncome,
    required this.projectedIncome,
    required this.projectedNetFlow,
    required this.daysElapsed,
    required this.totalDays,
    required this.reliability,
    required this.budgetsAtRisk,
  });

  final double currentExpense;
  final double projectedExpense;
  final double currentIncome;
  final double projectedIncome;
  final double projectedNetFlow;
  final int daysElapsed;
  final int totalDays;
  final ProjectionReliability reliability;
  final List<BudgetRisk> budgetsAtRisk;
}
