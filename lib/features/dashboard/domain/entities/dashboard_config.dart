import 'dashboard_card_type.dart';

class DashboardConfig {
  const DashboardConfig({required this.activeCards});

  final List<DashboardCardType> activeCards;

  static const DashboardConfig defaultConfig = DashboardConfig(
    activeCards: [
      DashboardCardType.monthlyFlow,
      DashboardCardType.totalBalance,
      DashboardCardType.budgetSummary,
      DashboardCardType.expenseBreakdown,
      DashboardCardType.monthlyComparison,
      DashboardCardType.projection,
      DashboardCardType.insights,
    ],
  );
}
