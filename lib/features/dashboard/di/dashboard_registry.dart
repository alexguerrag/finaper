import '../../../app/di/app_locator.dart';

import 'dashboard_module.dart';

class DashboardRegistry {
  DashboardRegistry._();

  static DashboardModule get module => AppLocator.get<DashboardModule>();
}
