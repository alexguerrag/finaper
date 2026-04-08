import '../../../app/di/app_locator.dart';

import 'goals_module.dart';

class GoalsRegistry {
  GoalsRegistry._();

  static GoalsModule get module => AppLocator.get<GoalsModule>();
}
