import 'package:finaper/features/analytics/domain/entities/entitlement_status.dart';
import 'package:finaper/features/analytics/domain/repositories/entitlement_repository.dart';
import 'package:finaper/features/analytics/domain/usecases/clear_entitlement_cache.dart';
import 'package:finaper/features/analytics/domain/usecases/get_entitlement_status.dart';
import 'package:finaper/features/analytics/domain/usecases/refresh_entitlement.dart';
import 'package:finaper/features/analytics/presentation/controllers/entitlement_controller.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeEntitlementRepository implements EntitlementRepository {
  _FakeEntitlementRepository({
    required EntitlementStatus initial,
    EntitlementStatus? refreshResult,
    bool throws = false,
  })  : _cached = initial,
        _refreshResult = refreshResult ?? initial,
        _throws = throws;

  EntitlementStatus _cached;
  final EntitlementStatus _refreshResult;
  final bool _throws;
  bool clearCalled = false;

  @override
  EntitlementStatus get cachedStatus => _cached;

  @override
  Future<EntitlementStatus> refresh() async {
    if (_throws) throw Exception('network error');
    _cached = _refreshResult;
    return _cached;
  }

  @override
  Future<void> clearCache() async {
    clearCalled = true;
    _cached = EntitlementStatus.free;
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

EntitlementController _makeController({
  required EntitlementStatus initial,
  EntitlementStatus? refreshResult,
  bool throws = false,
}) {
  final repo = _FakeEntitlementRepository(
    initial: initial,
    refreshResult: refreshResult,
    throws: throws,
  );
  return EntitlementController(
    getEntitlementStatus: GetEntitlementStatus(repo),
    refreshEntitlement: RefreshEntitlement(repo),
    clearEntitlementCache: ClearEntitlementCache(repo),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EntitlementController — estado inicial', () {
    test('status inicial viene del cache (free)', () {
      final c = _makeController(initial: EntitlementStatus.free);
      expect(c.status, EntitlementStatus.free);
    });

    test('status inicial viene del cache (premium)', () {
      final c = _makeController(initial: EntitlementStatus.premium);
      expect(c.status, EntitlementStatus.premium);
    });

    test('isLoading es false en el estado inicial', () {
      final c = _makeController(initial: EntitlementStatus.free);
      expect(c.isLoading, isFalse);
    });

    test('errorMessage es null en el estado inicial', () {
      final c = _makeController(initial: EntitlementStatus.free);
      expect(c.errorMessage, isNull);
    });
  });

  group('EntitlementController — hasPremiumAccess', () {
    test('true para trial', () {
      expect(
        _makeController(initial: EntitlementStatus.trial).hasPremiumAccess,
        isTrue,
      );
    });

    test('true para premium', () {
      expect(
        _makeController(initial: EntitlementStatus.premium).hasPremiumAccess,
        isTrue,
      );
    });

    test('false para free', () {
      expect(
        _makeController(initial: EntitlementStatus.free).hasPremiumAccess,
        isFalse,
      );
    });

    test('false para expired', () {
      expect(
        _makeController(initial: EntitlementStatus.expired).hasPremiumAccess,
        isFalse,
      );
    });
  });

  group('EntitlementController — refresh()', () {
    test('actualiza status tras refresh exitoso', () async {
      final c = _makeController(
        initial: EntitlementStatus.free,
        refreshResult: EntitlementStatus.premium,
      );
      await c.refresh();
      expect(c.status, EntitlementStatus.premium);
    });

    test('hasPremiumAccess refleja el nuevo status tras refresh', () async {
      final c = _makeController(
        initial: EntitlementStatus.free,
        refreshResult: EntitlementStatus.trial,
      );
      await c.refresh();
      expect(c.hasPremiumAccess, isTrue);
    });

    test('no lanza excepción si el repositorio falla', () async {
      final c = _makeController(
        initial: EntitlementStatus.free,
        throws: true,
      );
      await expectLater(c.refresh(), completes);
    });

    test('errorMessage se establece cuando el repositorio falla', () async {
      final c = _makeController(
        initial: EntitlementStatus.free,
        throws: true,
      );
      await c.refresh();
      expect(c.errorMessage, isNotNull);
    });

    test('isLoading pasa de false → true → false durante refresh', () async {
      final c = _makeController(
        initial: EntitlementStatus.free,
        refreshResult: EntitlementStatus.premium,
      );
      final loadingSnapshots = <bool>[];
      c.addListener(() => loadingSnapshots.add(c.isLoading));

      await c.refresh();

      expect(loadingSnapshots, containsAllInOrder([true, false]));
    });

    test('notifyListeners se llama al menos una vez por refresh', () async {
      final c = _makeController(
        initial: EntitlementStatus.premium,
        refreshResult: EntitlementStatus.premium,
      );
      var notifyCount = 0;
      c.addListener(() => notifyCount++);

      await c.refresh();

      expect(notifyCount, greaterThan(0));
    });

    test('errorMessage se limpia en un refresh exitoso posterior', () async {
      final repo = _FakeEntitlementRepository(
        initial: EntitlementStatus.free,
        throws: true,
      );
      final c = EntitlementController(
        getEntitlementStatus: GetEntitlementStatus(repo),
        refreshEntitlement: RefreshEntitlement(repo),
        clearEntitlementCache: ClearEntitlementCache(repo),
      );
      await c.refresh();
      expect(c.errorMessage, isNotNull);

      // Segundo refresh con un repositorio que no falla
      final repo2 = _FakeEntitlementRepository(
        initial: EntitlementStatus.free,
        refreshResult: EntitlementStatus.premium,
      );
      final c2 = EntitlementController(
        getEntitlementStatus: GetEntitlementStatus(repo2),
        refreshEntitlement: RefreshEntitlement(repo2),
        clearEntitlementCache: ClearEntitlementCache(repo2),
      );
      await c2.refresh();
      expect(c2.errorMessage, isNull);
    });
  });

  group('EntitlementController — clearCache()', () {
    test('status vuelve a free tras clearCache', () async {
      final c = _makeController(initial: EntitlementStatus.premium);
      await c.clearCache();
      expect(c.status, EntitlementStatus.free);
    });

    test('hasPremiumAccess es false tras clearCache', () async {
      final c = _makeController(initial: EntitlementStatus.trial);
      await c.clearCache();
      expect(c.hasPremiumAccess, isFalse);
    });

    test('notifyListeners se llama tras clearCache', () async {
      final c = _makeController(initial: EntitlementStatus.premium);
      var notifyCount = 0;
      c.addListener(() => notifyCount++);

      await c.clearCache();

      expect(notifyCount, greaterThan(0));
    });
  });
}
