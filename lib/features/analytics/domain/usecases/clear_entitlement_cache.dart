import '../repositories/entitlement_repository.dart';

class ClearEntitlementCache {
  const ClearEntitlementCache(this.repository);

  final EntitlementRepository repository;

  Future<void> call() => repository.clearCache();
}
