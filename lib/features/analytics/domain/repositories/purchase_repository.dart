import '../entities/premium_package.dart';

abstract class PurchaseRepository {
  Future<List<PremiumPackage>> getPackages();
  Future<void> purchase(PremiumPackage package);

  /// Devuelve true si se restauró al menos una compra con acceso Premium activo.
  Future<bool> restorePurchases();
}
