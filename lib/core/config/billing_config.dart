/// Compile-time billing configuration injected via --dart-define.
///
/// Required defines for a functional RevenueCat integration:
///   --dart-define=REVENUECAT_ANDROID_API_KEY=YOUR_KEY
///   --dart-define=REVENUECAT_ENTITLEMENT_ID=YOUR_ID
///
/// If either value is absent or empty, [isConfigured] returns false and
/// RevenueCat must NOT be initialized (no crash, graceful no-op).
abstract final class BillingConfig {
  static const String androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );

  static const String entitlementId = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT_ID',
  );

  /// True only when both required values are present at compile-time.
  /// Guards every RevenueCat call-site — never initialize if false.
  static const bool isConfigured =
      androidApiKey != '' && entitlementId != '';
}
