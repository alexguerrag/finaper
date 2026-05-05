import 'package:finaper/features/analytics/data/datasources/entitlement_remote_datasource.dart';
import 'package:finaper/features/analytics/data/datasources/local_entitlement_cache_datasource.dart';
import 'package:finaper/features/analytics/data/repositories/entitlement_repository_impl.dart';
import 'package:finaper/features/analytics/domain/entities/entitlement_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<LocalEntitlementCacheDataSource> cacheFrom(
    Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  return LocalEntitlementCacheDataSource(prefs);
}

Future<LocalEntitlementCacheDataSource> emptyCache() => cacheFrom({});

String iso(DateTime dt) => dt.toIso8601String();

// ---------------------------------------------------------------------------
// Fake remote datasource
// ---------------------------------------------------------------------------

class _FakeRemote implements EntitlementRemoteDataSource {
  _FakeRemote({EntitlementStatus? result, bool throws = false})
      : _result = result,
        _throws = throws;

  final EntitlementStatus? _result;
  final bool _throws;
  int callCount = 0;

  @override
  Future<EntitlementStatus> fetchStatus() async {
    callCount++;
    if (_throws) throw Exception('network error');
    return _result!;
  }
}

// ---------------------------------------------------------------------------
// LocalEntitlementCacheDataSource tests
// ---------------------------------------------------------------------------

void main() {
  group('LocalEntitlementCacheDataSource', () {
    test('readSync returns null when cache is empty', () async {
      final cache = await emptyCache();
      expect(cache.readSync(), isNull);
    });

    test('readSync returns written status within maxAge', () async {
      final cache = await emptyCache();
      await cache.write(EntitlementStatus.premium, DateTime.now());
      expect(cache.readSync(), EntitlementStatus.premium);
    });

    test('readSync returns null when fetchedAt is older than 7 days', () async {
      final stale = DateTime.now().subtract(const Duration(days: 7));
      final cache = await cacheFrom({
        'finaper.entitlement.status': 'premium',
        'finaper.entitlement.fetched_at': iso(stale),
      });
      expect(cache.readSync(), isNull);
    });

    test('readSync returns status when fetchedAt is 6 days old (still valid)',
        () async {
      final recent = DateTime.now().subtract(const Duration(days: 6));
      final cache = await cacheFrom({
        'finaper.entitlement.status': 'trial',
        'finaper.entitlement.fetched_at': iso(recent),
      });
      expect(cache.readSync(), EntitlementStatus.trial);
    });

    test('readSync returns null when fetchedAt string is corrupted', () async {
      final cache = await cacheFrom({
        'finaper.entitlement.status': 'premium',
        'finaper.entitlement.fetched_at': 'not-a-date',
      });
      expect(cache.readSync(), isNull);
    });

    test('readSync returns null when status key is missing', () async {
      final cache = await cacheFrom({
        'finaper.entitlement.fetched_at': iso(DateTime.now()),
      });
      expect(cache.readSync(), isNull);
    });

    test('readSync returns null for unknown status string', () async {
      final cache = await cacheFrom({
        'finaper.entitlement.status': 'unknown_value',
        'finaper.entitlement.fetched_at': iso(DateTime.now()),
      });
      expect(cache.readSync(), isNull);
    });

    test('write persists all EntitlementStatus values correctly', () async {
      for (final status in EntitlementStatus.values) {
        final cache = await emptyCache();
        await cache.write(status, DateTime.now());
        expect(cache.readSync(), status);
      }
    });

    test('clear removes both keys so readSync returns null', () async {
      final cache = await emptyCache();
      await cache.write(EntitlementStatus.premium, DateTime.now());
      await cache.clear();
      expect(cache.readSync(), isNull);
    });

    test('write overwrites previous value', () async {
      final cache = await emptyCache();
      await cache.write(EntitlementStatus.trial, DateTime.now());
      await cache.write(EntitlementStatus.expired, DateTime.now());
      expect(cache.readSync(), EntitlementStatus.expired);
    });

    test('readSync returns null exactly at 7-day boundary', () async {
      final boundary =
          DateTime.now().subtract(const Duration(days: 7, seconds: 1));
      final cache = await cacheFrom({
        'finaper.entitlement.status': 'premium',
        'finaper.entitlement.fetched_at': iso(boundary),
      });
      expect(cache.readSync(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // EntitlementRepositoryImpl tests
  // -------------------------------------------------------------------------

  group('EntitlementRepositoryImpl', () {
    Future<EntitlementRepositoryImpl> makeRepo({
      required _FakeRemote remote,
      Map<String, Object> prefs = const {},
      bool isConfigured = false,
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      final sp = await SharedPreferences.getInstance();
      final cache = LocalEntitlementCacheDataSource(sp);
      return EntitlementRepositoryImpl(
        remote: remote,
        cache: cache,
        isConfigured: isConfigured,
      );
    }

    test('cachedStatus is free when no cache exists at construction', () async {
      final repo = await makeRepo(remote: _FakeRemote(result: EntitlementStatus.premium));
      expect(repo.cachedStatus, EntitlementStatus.free);
    });

    test('cachedStatus reflects valid cache at construction', () async {
      final recent = DateTime.now().subtract(const Duration(hours: 1));
      final repo = await makeRepo(
        remote: _FakeRemote(result: EntitlementStatus.premium),
        prefs: {
          'finaper.entitlement.status': 'trial',
          'finaper.entitlement.fetched_at': iso(recent),
        },
      );
      expect(repo.cachedStatus, EntitlementStatus.trial);
    });

    test('refresh returns cachedStatus when billing is not configured',
        () async {
      final remote = _FakeRemote(result: EntitlementStatus.premium);
      final repo = await makeRepo(remote: remote, isConfigured: false);
      final result = await repo.refresh();
      expect(result, EntitlementStatus.free);
      expect(remote.callCount, 0);
    });

    test('refresh fetches remote and updates cachedStatus when configured',
        () async {
      final remote = _FakeRemote(result: EntitlementStatus.premium);
      final repo = await makeRepo(remote: remote, isConfigured: true);
      final result = await repo.refresh();
      expect(result, EntitlementStatus.premium);
      expect(repo.cachedStatus, EntitlementStatus.premium);
      expect(remote.callCount, 1);
    });

    test('refresh falls back to valid cache when remote throws', () async {
      final recent = DateTime.now().subtract(const Duration(hours: 2));
      final remote = _FakeRemote(throws: true);
      final repo = await makeRepo(
        remote: remote,
        isConfigured: true,
        prefs: {
          'finaper.entitlement.status': 'trial',
          'finaper.entitlement.fetched_at': iso(recent),
        },
      );
      final result = await repo.refresh();
      expect(result, EntitlementStatus.trial);
    });

    test('refresh returns free when remote throws and cache is absent',
        () async {
      final remote = _FakeRemote(throws: true);
      final repo = await makeRepo(remote: remote, isConfigured: true);
      final result = await repo.refresh();
      expect(result, EntitlementStatus.free);
    });

    test('refresh returns free when remote throws and cache is stale',
        () async {
      final stale = DateTime.now().subtract(const Duration(days: 8));
      final remote = _FakeRemote(throws: true);
      final repo = await makeRepo(
        remote: remote,
        isConfigured: true,
        prefs: {
          'finaper.entitlement.status': 'premium',
          'finaper.entitlement.fetched_at': iso(stale),
        },
      );
      final result = await repo.refresh();
      expect(result, EntitlementStatus.free);
    });

    test('clearCache resets cachedStatus to free', () async {
      final recent = DateTime.now().subtract(const Duration(hours: 1));
      final repo = await makeRepo(
        remote: _FakeRemote(result: EntitlementStatus.premium),
        prefs: {
          'finaper.entitlement.status': 'premium',
          'finaper.entitlement.fetched_at': iso(recent),
        },
      );
      await repo.clearCache();
      expect(repo.cachedStatus, EntitlementStatus.free);
    });

    test('clearCache causes subsequent readSync on cache to return null',
        () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final cache = LocalEntitlementCacheDataSource(sp);
      final repo = EntitlementRepositoryImpl(
        remote: _FakeRemote(result: EntitlementStatus.premium),
        cache: cache,
        isConfigured: false,
      );
      await cache.write(EntitlementStatus.premium, DateTime.now());
      await repo.clearCache();
      expect(cache.readSync(), isNull);
    });

    test(
        'refresh with isConfigured=true stores result so cachedStatus reflects it',
        () async {
      final remote = _FakeRemote(result: EntitlementStatus.expired);
      final repo = await makeRepo(remote: remote, isConfigured: true);
      await repo.refresh();
      expect(repo.cachedStatus, EntitlementStatus.expired);
    });
  });
}
