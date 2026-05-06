import '../entities/premium_package.dart';
import '../repositories/purchase_repository.dart';

class GetPackages {
  const GetPackages(this.repository);

  final PurchaseRepository repository;

  Future<List<PremiumPackage>> call() => repository.getPackages();
}
