import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/entitlement_status.dart';

/// Persists entitlement status and its fetch timestamp in SharedPreferences.
///
/// Cache validity rules:
/// - Age < 7 days  → valid; [readSync] returns the stored status.
/// - Age >= 7 days → stale; [readSync] returns null.
/// - Missing or corrupted data → [readSync] returns null.
///
/// Only entitlement state and a timestamp are stored — no PII.
class LocalEntitlementCacheDataSource {
  const LocalEntitlementCacheDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String _statusKey = 'finaper.entitlement.status';
  static const String _fetchedAtKey = 'finaper.entitlement.fetched_at';
  static const Duration _maxAge = Duration(days: 7);

  /// Returns the cached [EntitlementStatus], or null if the cache is absent,
  /// corrupted, or older than [_maxAge].
  ///
  /// Reads synchronously from the already-loaded [SharedPreferences] instance.
  EntitlementStatus? readSync() {
    final statusStr = _prefs.getString(_statusKey);
    final fetchedAtStr = _prefs.getString(_fetchedAtKey);

    if (statusStr == null || fetchedAtStr == null) return null;

    final DateTime fetchedAt;
    try {
      fetchedAt = DateTime.parse(fetchedAtStr);
    } catch (_) {
      return null;
    }

    if (DateTime.now().difference(fetchedAt) >= _maxAge) return null;

    return _parseStatus(statusStr);
  }

  Future<void> write(EntitlementStatus status, DateTime fetchedAt) async {
    await _prefs.setString(_statusKey, status.name);
    await _prefs.setString(_fetchedAtKey, fetchedAt.toIso8601String());
  }

  Future<void> clear() async {
    await _prefs.remove(_statusKey);
    await _prefs.remove(_fetchedAtKey);
  }

  static EntitlementStatus? _parseStatus(String value) {
    for (final s in EntitlementStatus.values) {
      if (s.name == value) return s;
    }
    return null;
  }
}
