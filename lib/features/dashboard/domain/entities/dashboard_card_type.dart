enum DashboardCardType {
  monthlyFlow,
  totalBalance,
  budgetSummary,
  expenseBreakdown,
  projection,
  insights,
}

extension DashboardCardTypeX on DashboardCardType {
  bool get isPremium =>
      this == DashboardCardType.projection ||
      this == DashboardCardType.insights;
}
