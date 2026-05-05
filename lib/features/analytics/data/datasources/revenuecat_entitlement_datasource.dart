import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/config/billing_config.dart';
import '../../domain/entities/entitlement_status.dart';
import 'entitlement_remote_datasource.dart';

/// Fetches entitlement status from RevenueCat.
///
/// Mapping rules:
/// - Active entitlement + periodType == trial  → [EntitlementStatus.trial]
/// - Active entitlement + any other periodType → [EntitlementStatus.premium]
/// - Inactive entitlement found in history     → [EntitlementStatus.expired]
/// - Entitlement never recorded               → [EntitlementStatus.free]
///
/// Note: RevenueCat intro-price periods (periodType == intro) are mapped to
/// [EntitlementStatus.premium] because the user has paid, just at a discount.
class RevenueCatEntitlementDataSource implements EntitlementRemoteDataSource {
  const RevenueCatEntitlementDataSource();

  @override
  Future<EntitlementStatus> fetchStatus() async {
    if (!BillingConfig.isConfigured) {
      throw const _EntitlementNotConfiguredException();
    }

    final info = await Purchases.getCustomerInfo();
    final active = info.entitlements.active[BillingConfig.entitlementId];

    if (active != null) {
      return active.periodType == PeriodType.trial
          ? EntitlementStatus.trial
          : EntitlementStatus.premium;
    }

    // Entitlement not currently active — check history for expired state.
    final all = info.entitlements.all[BillingConfig.entitlementId];
    return all != null ? EntitlementStatus.expired : EntitlementStatus.free;
  }
}

class _EntitlementNotConfiguredException implements Exception {
  const _EntitlementNotConfiguredException();

  @override
  String toString() =>
      'RevenueCat is not configured. Provide REVENUECAT_ANDROID_API_KEY '
      'and REVENUECAT_ENTITLEMENT_ID via --dart-define.';
}
