import '../../../app/di/app_module.dart';
import '../../budgets/di/budgets_registry.dart';
import '../../transactions/di/transactions_registry.dart';
import '../data/repositories/analytics_repository_impl.dart';
import '../data/services/local_entitlement_service.dart';
import '../domain/repositories/analytics_repository.dart';
import '../domain/services/entitlement_service.dart';
import '../domain/usecases/get_premium_reports.dart';
import '../presentation/controllers/premium_reports_controller.dart';

class AnalyticsModule implements AppModule {
  late final AnalyticsRepository repository;
  late final EntitlementService entitlementService;
  late final GetPremiumReports getPremiumReports;
  late final PremiumReportsController controller;

  @override
  Future<void> register() async {
    repository = AnalyticsRepositoryImpl(
      transactionsRepository: TransactionsRegistry.module.repository,
      budgetsRepository: BudgetsRegistry.module.repository,
    );
    entitlementService = const LocalEntitlementService();
    getPremiumReports = GetPremiumReports(repository);
    controller = PremiumReportsController(getPremiumReports: getPremiumReports);
  }
}
