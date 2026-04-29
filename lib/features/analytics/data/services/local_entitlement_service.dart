import '../../domain/services/entitlement_service.dart';

class LocalEntitlementService implements EntitlementService {
  const LocalEntitlementService();

  @override
  bool get hasPremiumAccess => true;
}
