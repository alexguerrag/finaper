import 'package:finaper/app/bootstrap/bootstrap_status.dart';
import 'package:flutter_test/flutter_test.dart';

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
