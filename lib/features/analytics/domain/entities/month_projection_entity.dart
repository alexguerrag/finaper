enum ProjectionReliability {
  low,    // day 1–9  — not enough data, income not extrapolated
  medium, // day 10–15 — estimating, show with caution badge
  high,   // day 16+  — reliable enough to show confidently
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
    required this.isSanityFailed,
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

  /// True when the projected income exceeds 3× the user's historical monthly
  /// average — signals an unreliable extrapolation (e.g. large one-off income
  /// recorded early in the month).
  final bool isSanityFailed;

  /// Whether the UI should display projected amounts.
  /// Hidden when there is too little data (LOW) or the sanity check fails.
  bool get showProjectedAmounts =>
      reliability != ProjectionReliability.low && !isSanityFailed;
}
