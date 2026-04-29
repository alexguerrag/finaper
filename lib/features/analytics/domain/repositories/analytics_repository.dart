import '../entities/premium_reports_entity.dart';

abstract class AnalyticsRepository {
  Future<PremiumReportsEntity> getReports({required DateTime month});
}
