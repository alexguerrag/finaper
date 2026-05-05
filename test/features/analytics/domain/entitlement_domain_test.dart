import 'package:finaper/features/analytics/domain/entities/entitlement_status.dart';
import 'package:finaper/features/analytics/domain/repositories/entitlement_repository.dart';
import 'package:finaper/features/analytics/domain/usecases/clear_entitlement_cache.dart';
import 'package:finaper/features/analytics/domain/usecases/get_entitlement_status.dart';
import 'package:finaper/features/analytics/domain/usecases/refresh_entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeEntitlementRepository implements EntitlementRepository {
  _FakeEntitlementRepository({
    required EntitlementStatus initial,
    EntitlementStatus? refreshResult,
  })  : _cached = initial,
        _refreshResult = refreshResult ?? initial;

  EntitlementStatus _cached;
  final EntitlementStatus _refreshResult;
  bool clearCalled = false;

  @override
  EntitlementStatus get cachedStatus => _cached;

  @override
  Future<EntitlementStatus> refresh() async {
    _cached = _refreshResult;
    return _cached;
  }

  @override
  Future<void> clearCache() async {
    clearCalled = true;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── EntitlementStatusX — hasPremiumAccess ────────────────────────────────

  group('EntitlementStatusX.hasPremiumAccess', () {
    test('trial grants premium access', () {
      expect(EntitlementStatus.trial.hasPremiumAccess, isTrue);
    });

    test('premium grants premium access', () {
      expect(EntitlementStatus.premium.hasPremiumAccess, isTrue);
    });

    test('free does not grant premium access', () {
      expect(EntitlementStatus.free.hasPremiumAccess, isFalse);
    });

    test('expired does not grant premium access', () {
      expect(EntitlementStatus.expired.hasPremiumAccess, isFalse);
    });
  });

  // ── EntitlementStatusX — helpers ─────────────────────────────────────────

  group('EntitlementStatusX helpers', () {
    test('isPaid is true only for premium', () {
      expect(EntitlementStatus.premium.isPaid, isTrue);
      expect(EntitlementStatus.trial.isPaid, isFalse);
      expect(EntitlementStatus.free.isPaid, isFalse);
      expect(EntitlementStatus.expired.isPaid, isFalse);
    });

    test('isTrial is true only for trial', () {
      expect(EntitlementStatus.trial.isTrial, isTrue);
      expect(EntitlementStatus.premium.isTrial, isFalse);
      expect(EntitlementStatus.free.isTrial, isFalse);
      expect(EntitlementStatus.expired.isTrial, isFalse);
    });

    test('isExpired is true only for expired', () {
      expect(EntitlementStatus.expired.isExpired, isTrue);
      expect(EntitlementStatus.premium.isExpired, isFalse);
      expect(EntitlementStatus.trial.isExpired, isFalse);
      expect(EntitlementStatus.free.isExpired, isFalse);
    });
  });

  // ── GetEntitlementStatus ─────────────────────────────────────────────────

  group('GetEntitlementStatus', () {
    test('returns cachedStatus from repository', () {
      final repo = _FakeEntitlementRepository(initial: EntitlementStatus.premium);
      final useCase = GetEntitlementStatus(repo);

      expect(useCase(), EntitlementStatus.premium);
    });

    test('returns free when cached status is free', () {
      final repo = _FakeEntitlementRepository(initial: EntitlementStatus.free);
      final useCase = GetEntitlementStatus(repo);

      expect(useCase(), EntitlementStatus.free);
    });
  });

  // ── RefreshEntitlement ───────────────────────────────────────────────────

  group('RefreshEntitlement', () {
    test('calls repository.refresh() and returns result', () async {
      final repo = _FakeEntitlementRepository(
        initial: EntitlementStatus.free,
        refreshResult: EntitlementStatus.premium,
      );
      final useCase = RefreshEntitlement(repo);

      final result = await useCase();

      expect(result, EntitlementStatus.premium);
      expect(repo.cachedStatus, EntitlementStatus.premium);
    });

    test('propagates expired status from refresh', () async {
      final repo = _FakeEntitlementRepository(
        initial: EntitlementStatus.premium,
        refreshResult: EntitlementStatus.expired,
      );
      final useCase = RefreshEntitlement(repo);

      final result = await useCase();

      expect(result, EntitlementStatus.expired);
    });
  });

  // ── ClearEntitlementCache ────────────────────────────────────────────────

  group('ClearEntitlementCache', () {
    test('calls repository.clearCache()', () async {
      final repo = _FakeEntitlementRepository(initial: EntitlementStatus.premium);
      final useCase = ClearEntitlementCache(repo);

      await useCase();

      expect(repo.clearCalled, isTrue);
    });
  });
}
