import 'analytics_insight_entity.dart';
import 'cash_flow_entity.dart';
import 'ledger_entity.dart';
import 'month_projection_entity.dart';
import 'monthly_comparison_entity.dart';
import 'savings_rate_entity.dart';

class PremiumReportsEntity {
  const PremiumReportsEntity({
    required this.comparison,
    required this.projection,
    required this.insights,
    required this.month,
    required this.savingsRate,
    required this.cashFlow,
    required this.ledger,
  });

  final MonthlyComparisonEntity comparison;
  final MonthProjectionEntity projection;
  final List<AnalyticsInsightEntity> insights;
  final DateTime month;
  final SavingsRateEntity savingsRate;
  final CashFlowEntity cashFlow;
  final LedgerEntity ledger;
}
