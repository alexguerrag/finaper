import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/di/app_module.dart';
import '../../../core/config/billing_config.dart';
import '../../../core/logging/app_logger.dart';
import '../../budgets/di/budgets_registry.dart';
import '../../transactions/di/transactions_registry.dart';
import '../data/datasources/local_entitlement_cache_datasource.dart';
import '../data/datasources/revenuecat_entitlement_datasource.dart';
import '../data/repositories/analytics_repository_impl.dart';
import '../data/repositories/entitlement_repository_impl.dart';
import '../domain/repositories/analytics_repository.dart';
import '../domain/repositories/entitlement_repository.dart';
import '../domain/usecases/clear_entitlement_cache.dart';
import '../domain/usecases/get_entitlement_status.dart';
import '../domain/usecases/get_premium_reports.dart';
import '../domain/usecases/refresh_entitlement.dart';
import '../presentation/controllers/entitlement_controller.dart';
import '../presentation/controllers/premium_reports_controller.dart';

class AnalyticsModule implements AppModule {
  late final AnalyticsRepository repository;
  late final EntitlementRepository entitlementRepository;
  late final GetEntitlementStatus getEntitlementStatus;
  late final RefreshEntitlement refreshEntitlement;
  late final ClearEntitlementCache clearEntitlementCache;
  late final EntitlementController entitlementController;
  late final GetPremiumReports getPremiumReports;
  late final PremiumReportsController controller;

  static bool _revenueCatConfigured = false;

  @override
  Future<void> register() async {
    repository = AnalyticsRepositoryImpl(
      transactionsRepository: TransactionsRegistry.module.repository,
      budgetsRepository: BudgetsRegistry.module.repository,
    );

    if (BillingConfig.isConfigured && !_revenueCatConfigured) {
      try {
        await Purchases.configure(
          PurchasesConfiguration(BillingConfig.androidApiKey),
        );
        _revenueCatConfigured = true;
        AppLogger.info('AnalyticsModule', 'RevenueCat configurado');
      } catch (e) {
        AppLogger.error(
          'AnalyticsModule',
          'Error inicializando RevenueCat — se usará cache/free',
          error: e,
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final cache = LocalEntitlementCacheDataSource(prefs);

    entitlementRepository = EntitlementRepositoryImpl(
      remote: const RevenueCatEntitlementDataSource(),
      cache: cache,
    );

    getEntitlementStatus = GetEntitlementStatus(entitlementRepository);
    refreshEntitlement = RefreshEntitlement(entitlementRepository);
    clearEntitlementCache = ClearEntitlementCache(entitlementRepository);

    entitlementController = EntitlementController(
      getEntitlementStatus: getEntitlementStatus,
      refreshEntitlement: refreshEntitlement,
      clearEntitlementCache: clearEntitlementCache,
    );

    getPremiumReports = GetPremiumReports(repository);
    controller = PremiumReportsController(getPremiumReports: getPremiumReports);

    // Refresca estado real desde RevenueCat en background
    unawaited(entitlementController.refresh());
  }
}
