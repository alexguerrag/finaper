import 'package:finaper/features/settings/di/settings_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SettingsModule initializes without throwing', () async {
    final module = SettingsModule();

    await module.register();

    expect(module.controller, isNotNull);
  });
}
