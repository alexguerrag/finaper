import '../entities/entitlement_status.dart';

abstract class EntitlementRepository {
  EntitlementStatus get cachedStatus;

  Future<EntitlementStatus> refresh();

  Future<void> clearCache();
}
