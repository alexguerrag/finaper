import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/premium_package.dart';
import '../../domain/exceptions/purchase_exceptions.dart';
import '../../domain/usecases/get_packages.dart';
import '../../domain/usecases/purchase_package.dart';
import '../../domain/usecases/restore_purchases.dart';
import 'entitlement_controller.dart';

/// Resultado de una operación de compra o restauración.
enum PaywallOutcome {
  /// Compra o restore exitoso.
  success,

  /// El usuario canceló en la tienda (no mostrar error agresivo).
  cancelled,

  /// Restore completado pero sin compras previas asociadas.
  noRestore,

  /// Error de red, tienda u otro error inesperado.
  error,
}

class PaywallController extends ChangeNotifier {
  PaywallController({
    required GetPackages getPackages,
    required PurchasePackage purchasePackage,
    required RestorePurchases restorePurchases,
    required EntitlementController entitlementController,
  })  : _getPackages = getPackages,
        _purchasePackage = purchasePackage,
        _restorePurchases = restorePurchases,
        _entitlementController = entitlementController;

  final GetPackages _getPackages;
  final PurchasePackage _purchasePackage;
  final RestorePurchases _restorePurchases;
  final EntitlementController _entitlementController;

  List<PremiumPackage> _packages = [];
  PremiumPackage? _selectedPackage;

  // Inicia en true para evitar un flash de "no disponible" antes de cargar.
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;

  List<PremiumPackage> get packages => List.unmodifiable(_packages);
  PremiumPackage? get selectedPackage => _selectedPackage;
  bool get isLoading => _isLoading;
  bool get isPurchasing => _isPurchasing;
  String? get errorMessage => _errorMessage;

  Future<void> loadPackages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _packages = await _getPackages();
      // Pre-selecciona el paquete anual; si no hay, el primero disponible.
      _selectedPackage = _packages.firstWhere(
        (p) => p.period == PremiumPackagePeriod.annual,
        orElse: () => _packages.first,
      );
    } catch (_) {
      _packages = [];
      _selectedPackage = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectPackage(PremiumPackage package) {
    _selectedPackage = package;
    notifyListeners();
  }

  Future<PaywallOutcome> purchaseSelected() async {
    final package = _selectedPackage;
    if (package == null) return PaywallOutcome.error;

    _isPurchasing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _purchasePackage(package);
      await _entitlementController.refresh();
      return PaywallOutcome.success;
    } on PurchaseCancelledException {
      return PaywallOutcome.cancelled;
    } catch (e, s) {
      _errorMessage = 'No se pudo completar la compra. Intenta de nuevo.';
      AppLogger.error('PaywallController', 'purchaseSelected falló', error: e, stackTrace: s);
      return PaywallOutcome.error;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  Future<PaywallOutcome> restorePurchases() async {
    _isPurchasing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hadPremium = await _restorePurchases();
      if (hadPremium) {
        await _entitlementController.refresh();
        return PaywallOutcome.success;
      }
      _errorMessage = 'No encontramos compras previas asociadas a esta cuenta.';
      return PaywallOutcome.noRestore;
    } catch (e, s) {
      _errorMessage = 'No se pudo restaurar la compra. Intenta de nuevo.';
      AppLogger.error('PaywallController', 'restorePurchases falló', error: e, stackTrace: s);
      return PaywallOutcome.error;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }
}
