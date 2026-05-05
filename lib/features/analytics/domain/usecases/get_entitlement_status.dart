import '../entities/entitlement_status.dart';
import '../repositories/entitlement_repository.dart';

class GetEntitlementStatus {
  const GetEntitlementStatus(this.repository);

  final EntitlementRepository repository;

  EntitlementStatus call() => repository.cachedStatus;
}
