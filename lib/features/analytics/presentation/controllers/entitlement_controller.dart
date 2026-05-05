import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/entitlement_status.dart';
import '../../domain/usecases/clear_entitlement_cache.dart';
import '../../domain/usecases/get_entitlement_status.dart';
import '../../domain/usecases/refresh_entitlement.dart';

class EntitlementController extends ChangeNotifier {
  EntitlementController({
    required GetEntitlementStatus getEntitlementStatus,
    required RefreshEntitlement refreshEntitlement,
    required ClearEntitlementCache clearEntitlementCache,
  })  : _getEntitlementStatus = getEntitlementStatus,
        _refreshEntitlement = refreshEntitlement,
        _clearEntitlementCache = clearEntitlementCache,
        _status = getEntitlementStatus();

  final GetEntitlementStatus _getEntitlementStatus;
  final RefreshEntitlement _refreshEntitlement;
  final ClearEntitlementCache _clearEntitlementCache;

  EntitlementStatus _status;
  bool _isLoading = false;
  String? _errorMessage;

  EntitlementStatus get status => _status;
  bool get hasPremiumAccess => _status.hasPremiumAccess;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _status = await _refreshEntitlement();
    } catch (e, s) {
      _errorMessage = 'No se pudo verificar tu suscripción.';
      AppLogger.error('EntitlementController', 'refresh falló', error: e, stackTrace: s);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCache() async {
    await _clearEntitlementCache();
    _status = _getEntitlementStatus();
    notifyListeners();
  }
}
