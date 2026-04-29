enum DashboardCardType {
  monthlyFlow,
  totalBalance,
  budgetSummary,
  expenseBreakdown,
  monthlyComparison,
  projection,
  insights,
}

extension DashboardCardTypeX on DashboardCardType {
  bool get isPremium =>
      this == DashboardCardType.monthlyComparison ||
      this == DashboardCardType.projection ||
      this == DashboardCardType.insights;
}
