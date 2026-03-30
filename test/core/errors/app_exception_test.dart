import 'package:flutter_test/flutter_test.dart';
import 'package:finaper/core/errors/app_exception.dart';

void main() {
  group('AppException', () {
    test('should keep message and code', () {
      const exception = AppException(
        'Error controlado',
        code: 'controlled_error',
      );

      expect(exception.message, 'Error controlado');
      expect(exception.code, 'controlled_error');
      expect(exception.toString(), contains('controlled_error'));
    });
  });
}
