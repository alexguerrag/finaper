import 'analytics_insight_entity.dart';
import 'month_projection_entity.dart';
import 'monthly_comparison_entity.dart';

class PremiumReportsEntity {
  const PremiumReportsEntity({
    required this.comparison,
    required this.projection,
    required this.insights,
    required this.month,
  });

  final MonthlyComparisonEntity comparison;
  final MonthProjectionEntity projection;
  final List<AnalyticsInsightEntity> insights;
  final DateTime month;
}
