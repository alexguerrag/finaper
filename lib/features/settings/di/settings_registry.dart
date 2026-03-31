import '../../../app/di/app_locator.dart';

import 'settings_module.dart';

class SettingsRegistry {
  SettingsRegistry._();

  static SettingsModule get module => AppLocator.get<SettingsModule>();
}
