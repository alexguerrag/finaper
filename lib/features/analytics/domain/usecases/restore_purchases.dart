import '../repositories/purchase_repository.dart';

class RestorePurchases {
  const RestorePurchases(this.repository);

  final PurchaseRepository repository;

  Future<bool> call() => repository.restorePurchases();
}
