import '../entities/premium_package.dart';
import '../repositories/purchase_repository.dart';

class PurchasePackage {
  const PurchasePackage(this.repository);

  final PurchaseRepository repository;

  Future<void> call(PremiumPackage package) => repository.purchase(package);
}
