import 'package:finaper/features/analytics/domain/entities/entitlement_status.dart';
import 'package:finaper/features/analytics/domain/entities/premium_package.dart';
import 'package:finaper/features/analytics/domain/exceptions/purchase_exceptions.dart';
import 'package:finaper/features/analytics/domain/repositories/entitlement_repository.dart';
import 'package:finaper/features/analytics/domain/repositories/purchase_repository.dart';
import 'package:finaper/features/analytics/domain/usecases/clear_entitlement_cache.dart';
import 'package:finaper/features/analytics/domain/usecases/get_entitlement_status.dart';
import 'package:finaper/features/analytics/domain/usecases/get_packages.dart';
import 'package:finaper/features/analytics/domain/usecases/purchase_package.dart';
import 'package:finaper/features/analytics/domain/usecases/refresh_entitlement.dart';
import 'package:finaper/features/analytics/domain/usecases/restore_purchases.dart';
import 'package:finaper/features/analytics/presentation/controllers/entitlement_controller.dart';
import 'package:finaper/features/analytics/presentation/controllers/paywall_controller.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// [afterRefresh] simula el estado que devuelve RevenueCat después de una
/// compra o restore exitosos.
class _FakeEntitlementRepository implements EntitlementRepository {
  _FakeEntitlementRepository({
    EntitlementStatus initial = EntitlementStatus.free,
    EntitlementStatus? afterRefresh,
  })  : _status = initial,
        _afterRefresh = afterRefresh ?? initial;

  EntitlementStatus _status;
  final EntitlementStatus _afterRefresh;
  int refreshCount = 0;

  @override
  EntitlementStatus get cachedStatus => _status;

  @override
  Future<EntitlementStatus> refresh() async {
    refreshCount++;
    _status = _afterRefresh;
    return _status;
  }

  @override
  Future<void> clearCache() async => _status = EntitlementStatus.free;
}

class _FakePurchaseRepository implements PurchaseRepository {
  _FakePurchaseRepository({
    List<PremiumPackage>? packages,
    bool throwOnPurchase = false,
    bool cancelOnPurchase = false,
    bool restoreResult = false,
    bool throwOnRestore = false,
  })  : _packages = packages ?? [],
        _throwOnPurchase = throwOnPurchase,
        _cancelOnPurchase = cancelOnPurchase,
        _restoreResult = restoreResult,
        _throwOnRestore = throwOnRestore;

  final List<PremiumPackage> _packages;
  final bool _throwOnPurchase;
  final bool _cancelOnPurchase;
  final bool _restoreResult;
  final bool _throwOnRestore;

  @override
  Future<List<PremiumPackage>> getPackages() async => _packages;

  @override
  Future<void> purchase(PremiumPackage package) async {
    if (_cancelOnPurchase) throw const PurchaseCancelledException();
    if (_throwOnPurchase) throw Exception('error de red');
  }

  @override
  Future<bool> restorePurchases() async {
    if (_throwOnRestore) throw Exception('error de restore');
    return _restoreResult;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PremiumPackage _fakePackage({
  String id = 'monthly',
  PremiumPackagePeriod period = PremiumPackagePeriod.monthly,
}) =>
    PremiumPackage(
      id: id,
      title: period == PremiumPackagePeriod.annual ? 'Anual' : 'Mensual',
      priceString: r'$9.99',
      period: period,
      rawPackage: Object(),
    );

PaywallController _makeController({
  List<PremiumPackage>? packages,
  bool throwOnPurchase = false,
  bool cancelOnPurchase = false,
  bool restoreResult = false,
  bool throwOnRestore = false,
  EntitlementStatus entitlementAfterRefresh = EntitlementStatus.free,
}) {
  final entitlementRepo = _FakeEntitlementRepository(
    afterRefresh: entitlementAfterRefresh,
  );
  final entitlementCtrl = EntitlementController(
    getEntitlementStatus: GetEntitlementStatus(entitlementRepo),
    refreshEntitlement: RefreshEntitlement(entitlementRepo),
    clearEntitlementCache: ClearEntitlementCache(entitlementRepo),
  );

  final purchaseRepo = _FakePurchaseRepository(
    packages: packages,
    throwOnPurchase: throwOnPurchase,
    cancelOnPurchase: cancelOnPurchase,
    restoreResult: restoreResult,
    throwOnRestore: throwOnRestore,
  );

  return PaywallController(
    getPackages: GetPackages(purchaseRepo),
    purchasePackage: PurchasePackage(purchaseRepo),
    restorePurchases: RestorePurchases(purchaseRepo),
    entitlementController: entitlementCtrl,
  );
}

({PaywallController ctrl, _FakeEntitlementRepository entitlementRepo})
    _makeControllerWithSpy({
  List<PremiumPackage>? packages,
  bool throwOnPurchase = false,
  bool cancelOnPurchase = false,
  bool restoreResult = false,
  EntitlementStatus entitlementAfterRefresh = EntitlementStatus.premium,
}) {
  final entitlementRepo = _FakeEntitlementRepository(
    afterRefresh: entitlementAfterRefresh,
  );
  final entitlementCtrl = EntitlementController(
    getEntitlementStatus: GetEntitlementStatus(entitlementRepo),
    refreshEntitlement: RefreshEntitlement(entitlementRepo),
    clearEntitlementCache: ClearEntitlementCache(entitlementRepo),
  );

  final purchaseRepo = _FakePurchaseRepository(
    packages: packages,
    throwOnPurchase: throwOnPurchase,
    cancelOnPurchase: cancelOnPurchase,
    restoreResult: restoreResult,
  );

  final ctrl = PaywallController(
    getPackages: GetPackages(purchaseRepo),
    purchasePackage: PurchasePackage(purchaseRepo),
    restorePurchases: RestorePurchases(purchaseRepo),
    entitlementController: entitlementCtrl,
  );

  return (ctrl: ctrl, entitlementRepo: entitlementRepo);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PaywallController — loadPackages()', () {
    test('carga packages correctamente', () async {
      final pkg = _fakePackage();
      final ctrl = _makeController(packages: [pkg]);

      await ctrl.loadPackages();

      expect(ctrl.packages, hasLength(1));
      expect(ctrl.packages.first.id, pkg.id);
    });

    test('pre-selecciona el paquete anual si está disponible', () async {
      final monthly = _fakePackage(id: 'monthly', period: PremiumPackagePeriod.monthly);
      final annual = _fakePackage(id: 'annual', period: PremiumPackagePeriod.annual);
      final ctrl = _makeController(packages: [monthly, annual]);

      await ctrl.loadPackages();

      expect(ctrl.selectedPackage?.id, 'annual');
    });

    test('sin packages disponibles: lista vacía, no crashea', () async {
      final ctrl = _makeController(packages: []);

      await expectLater(ctrl.loadPackages(), completes);

      expect(ctrl.packages, isEmpty);
      expect(ctrl.selectedPackage, isNull);
    });

    test('loadPackages con lista vacía no lanza excepción como control de flujo',
        () async {
      // _getPackages() retorna [] sin throw; loadPackages() debe terminar limpio.
      final ctrl = _makeController(packages: []);

      await ctrl.loadPackages();

      expect(ctrl.isLoading, isFalse);
      expect(ctrl.errorMessage, isNull);
    });

    test('isLoading vuelve a false después de loadPackages', () async {
      final ctrl = _makeController(packages: [_fakePackage()]);
      final snapshots = <bool>[];
      ctrl.addListener(() => snapshots.add(ctrl.isLoading));

      await ctrl.loadPackages();

      expect(snapshots.last, isFalse);
      expect(ctrl.isLoading, isFalse);
    });
  });

  group('PaywallController — purchaseSelected()', () {
    test('compra exitosa llama a EntitlementController.refresh()', () async {
      final pkg = _fakePackage();
      final (:ctrl, :entitlementRepo) = _makeControllerWithSpy(packages: [pkg]);

      await ctrl.loadPackages();
      final outcome = await ctrl.purchaseSelected();

      expect(outcome, PaywallOutcome.success);
      expect(entitlementRepo.refreshCount, greaterThan(0));
    });

    test(
        'compra exitosa pero hasPremiumAccess false retorna error con errorMessage',
        () async {
      // La compra se procesa pero el entitlement no queda activo (ej. delay de RC).
      final pkg = _fakePackage();
      final ctrl = _makeController(
        packages: [pkg],
        entitlementAfterRefresh: EntitlementStatus.free,
      );

      await ctrl.loadPackages();
      final outcome = await ctrl.purchaseSelected();

      expect(outcome, PaywallOutcome.error);
      expect(ctrl.errorMessage, isNotNull);
    });

    test('cancelación del usuario retorna cancelled sin errorMessage', () async {
      final pkg = _fakePackage();
      final ctrl = _makeController(packages: [pkg], cancelOnPurchase: true);

      await ctrl.loadPackages();
      final outcome = await ctrl.purchaseSelected();

      expect(outcome, PaywallOutcome.cancelled);
      expect(ctrl.errorMessage, isNull);
    });

    test('error de compra establece errorMessage', () async {
      final pkg = _fakePackage();
      final ctrl = _makeController(packages: [pkg], throwOnPurchase: true);

      await ctrl.loadPackages();
      await ctrl.purchaseSelected();

      expect(ctrl.errorMessage, isNotNull);
    });

    test('error de compra retorna PaywallOutcome.error', () async {
      final pkg = _fakePackage();
      final ctrl = _makeController(packages: [pkg], throwOnPurchase: true);

      await ctrl.loadPackages();
      final outcome = await ctrl.purchaseSelected();

      expect(outcome, PaywallOutcome.error);
    });
  });

  group('PaywallController — restorePurchases()', () {
    test('restore exitoso llama a EntitlementController.refresh()', () async {
      final (:ctrl, :entitlementRepo) = _makeControllerWithSpy(
        packages: [_fakePackage()],
        restoreResult: true,
      );

      final outcome = await ctrl.restorePurchases();

      expect(outcome, PaywallOutcome.success);
      expect(entitlementRepo.refreshCount, greaterThan(0));
    });

    test('restore disponible aunque no haya packages cargados', () async {
      // Simula que los offerings no cargaron pero el usuario tiene compra previa.
      final (:ctrl, :entitlementRepo) = _makeControllerWithSpy(
        packages: [],
        restoreResult: true,
      );

      // No se llama loadPackages() — packages permanece vacío.
      final outcome = await ctrl.restorePurchases();

      expect(outcome, PaywallOutcome.success);
      expect(entitlementRepo.refreshCount, greaterThan(0));
    });

    test('sin compras previas retorna noRestore con errorMessage', () async {
      final ctrl = _makeController(restoreResult: false);

      final outcome = await ctrl.restorePurchases();

      expect(outcome, PaywallOutcome.noRestore);
      expect(ctrl.errorMessage, isNotNull);
    });

    test('error de restore establece errorMessage y retorna error', () async {
      final ctrl = _makeController(throwOnRestore: true);

      final outcome = await ctrl.restorePurchases();

      expect(outcome, PaywallOutcome.error);
      expect(ctrl.errorMessage, isNotNull);
    });
  });

  group('PaywallController — selectPackage()', () {
    test('selectPackage cambia el selectedPackage', () async {
      final monthly = _fakePackage(id: 'monthly', period: PremiumPackagePeriod.monthly);
      final annual = _fakePackage(id: 'annual', period: PremiumPackagePeriod.annual);
      final ctrl = _makeController(packages: [monthly, annual]);

      await ctrl.loadPackages();
      ctrl.selectPackage(monthly);

      expect(ctrl.selectedPackage?.id, 'monthly');
    });
  });
}
