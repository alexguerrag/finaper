import '../../../../core/config/billing_config.dart';
import '../../domain/entities/entitlement_status.dart';
import '../../domain/repositories/entitlement_repository.dart';
import '../datasources/entitlement_remote_datasource.dart';
import '../datasources/local_entitlement_cache_datasource.dart';

class EntitlementRepositoryImpl implements EntitlementRepository {
  EntitlementRepositoryImpl({
    required EntitlementRemoteDataSource remote,
    required LocalEntitlementCacheDataSource cache,
    bool? isConfigured,
  })  : _remote = remote,
        _cache = cache,
        _isConfigured = isConfigured,
        _cached = cache.readSync() ?? EntitlementStatus.free;

  final EntitlementRemoteDataSource _remote;
  final LocalEntitlementCacheDataSource _cache;

  /// Overrides [BillingConfig.isConfigured] in tests.
  final bool? _isConfigured;

  EntitlementStatus _cached;

  bool get _billingConfigured {
    final override = _isConfigured;
    if (override != null) return override;
    return BillingConfig.isConfigured;
  }

  @override
  EntitlementStatus get cachedStatus =>
      BillingConfig.overridePremium ? EntitlementStatus.premium : _cached;

  @override
  Future<EntitlementStatus> refresh() async {
    if (BillingConfig.overridePremium) return EntitlementStatus.premium;

    if (!_billingConfigured) {
      return _cached;
    }

    try {
      final status = await _remote.fetchStatus();
      await _cache.write(status, DateTime.now());
      _cached = status;
      return _cached;
    } catch (_) {
      // RC unavailable — keep valid cache or degrade to free.
      final fromCache = _cache.readSync();
      _cached = fromCache ?? EntitlementStatus.free;
      return _cached;
    }
  }

  @override
  Future<void> clearCache() async {
    await _cache.clear();
    _cached = EntitlementStatus.free;
  }
}
