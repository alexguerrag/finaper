import 'package:finaper/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLogger methods execute without throwing', () {
    expect(() => AppLogger.info('test', 'info'), returnsNormally);
    expect(() => AppLogger.warning('test', 'warning'), returnsNormally);
    expect(
      () => AppLogger.error('test', 'error', error: 'sample'),
      returnsNormally,
    );
  });
}
