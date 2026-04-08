// ignore_for_file: deprecated_member_use_from_same_package

import 'package:finaper/app/di/app_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppServices compatibility shim initialize executes without throwing',
      () async {
    await AppServices.instance.initialize();
  });
}
