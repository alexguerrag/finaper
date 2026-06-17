import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/config/billing_config.dart';
import '../../domain/entities/premium_package.dart';
import '../../domain/exceptions/purchase_exceptions.dart';

class RevenueCatPurchaseDataSource {
  const RevenueCatPurchaseDataSource();

  Future<List<PremiumPackage>> getPackages() async {
    if (!BillingConfig.isConfigured) return [];
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return [];
      return current.availablePackages.map(_mapPackage).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> purchase(PremiumPackage package) async {
    final rcPackage = package.rawPackage as Package;
    try {
      await Purchases.purchasePackage(rcPackage);
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        throw const PurchaseCancelledException();
      }
      rethrow;
    }
  }

  /// Devuelve true si el restore activó al menos un entitlement Premium.
  Future<bool> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    return info.entitlements.active.containsKey(BillingConfig.entitlementId);
  }

  PremiumPackage _mapPackage(Package package) {
    final period = switch (package.packageType) {
      PackageType.monthly => PremiumPackagePeriod.monthly,
      PackageType.annual => PremiumPackagePeriod.annual,
      _ => PremiumPackagePeriod.other,
    };

    final title = switch (period) {
      PremiumPackagePeriod.monthly => 'Mensual',
      PremiumPackagePeriod.annual => 'Anual',
      PremiumPackagePeriod.other => package.storeProduct.title,
    };

    return PremiumPackage(
      id: package.identifier,
      title: title,
      priceString: package.storeProduct.priceString,
      period: period,
      rawPackage: package,
    );
  }
}
