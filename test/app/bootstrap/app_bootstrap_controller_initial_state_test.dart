import 'package:finaper/app/bootstrap/app_bootstrap_controller.dart';
import 'package:finaper/app/bootstrap/bootstrap_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppBootstrapController starts in idle state', () {
    final controller = AppBootstrapController();

    expect(controller.status, BootstrapStatus.idle);
    expect(controller.errorMessage, isNull);
    expect(controller.isInitializing, isFalse);
    expect(controller.isReady, isFalse);
    expect(controller.hasFailed, isFalse);

    controller.dispose();
  });
}
