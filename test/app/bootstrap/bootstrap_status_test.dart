import 'package:flutter_test/flutter_test.dart';
import 'package:finaper/app/bootstrap/bootstrap_status.dart';

void main() {
  group('BootstrapStatus', () {
    test('should expose expected states', () {
      expect(BootstrapStatus.values, contains(BootstrapStatus.idle));
      expect(BootstrapStatus.values, contains(BootstrapStatus.initializing));
      expect(BootstrapStatus.values, contains(BootstrapStatus.ready));
      expect(BootstrapStatus.values, contains(BootstrapStatus.failure));
    });
  });
}
