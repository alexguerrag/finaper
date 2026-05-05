import '../entities/entitlement_status.dart';
import '../repositories/entitlement_repository.dart';

class RefreshEntitlement {
  const RefreshEntitlement(this.repository);

  final EntitlementRepository repository;

  Future<EntitlementStatus> call() => repository.refresh();
}
