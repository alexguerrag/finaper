import '../../domain/entities/entitlement_status.dart';

abstract class EntitlementRemoteDataSource {
  /// Fetches the current entitlement status from the remote billing service.
  /// Throws if the service is unavailable or not configured.
  Future<EntitlementStatus> fetchStatus();
}
