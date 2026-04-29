import '../entities/premium_reports_entity.dart';
import '../repositories/analytics_repository.dart';

class GetPremiumReports {
  const GetPremiumReports(this._repository);

  final AnalyticsRepository _repository;

  Future<PremiumReportsEntity> call({required DateTime month}) =>
      _repository.getReports(month: month);
}
