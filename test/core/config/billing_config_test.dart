import 'package:finaper/core/config/billing_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillingConfig', () {
    test('androidApiKey is a String (empty when no --dart-define supplied)', () {
      expect(BillingConfig.androidApiKey, isA<String>());
    });

    test('entitlementId is a String (empty when no --dart-define supplied)', () {
      expect(BillingConfig.entitlementId, isA<String>());
    });

    test('isConfigured is false when no --dart-define values are supplied', () {
      // In the test runner no --dart-define flags are passed, so both values
      // are empty strings and isConfigured must be false.
      expect(BillingConfig.isConfigured, isFalse);
    });

    test('isConfigured is a bool', () {
      expect(BillingConfig.isConfigured, isA<bool>());
    });
  });
}
