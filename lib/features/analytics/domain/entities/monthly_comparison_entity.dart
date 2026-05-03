class CategoryDelta {
  const CategoryDelta({
    required this.categoryName,
    required this.currentAmount,
    required this.previousAmount,
    required this.deltaPercent,
  });

  final String categoryName;
  final double currentAmount;
  final double previousAmount;

  // (current - previous) / previous * 100
  // New categories (previous == 0) are never included.
  // Eliminated categories (current == 0) carry -100.
  final double deltaPercent;
}

class MonthlyComparisonEntity {
  const MonthlyComparisonEntity({
    required this.hasPreviousMonthData,
    required this.currentIncome,
    required this.currentExpense,
    required this.currentNetFlow,
    required this.previousIncome,
    required this.previousExpense,
    required this.previousNetFlow,
    required this.incomeDelta,
    required this.expenseDelta,
    required this.netFlowDelta,
    required this.topRising,
    required this.topFalling,
    this.cutoffDay,
  });

  final bool hasPreviousMonthData;

  final double currentIncome;
  final double currentExpense;
  final double currentNetFlow;

  final double previousIncome;
  final double previousExpense;
  final double previousNetFlow;

  // current - previous (positive = increased)
  final double incomeDelta;
  final double expenseDelta;
  final double netFlowDelta;

  // Max 2 each. topFalling includes eliminated categories (deltaPercent = -100).
  final List<CategoryDelta> topRising;
  final List<CategoryDelta> topFalling;

  /// Day of the month through which both months are compared (day-to-day mode).
  /// Null means a full-month comparison (used for historical months).
  final int? cutoffDay;
}
