import '../../../app/di/app_locator.dart';

import 'budgets_module.dart';

class BudgetsRegistry {
  BudgetsRegistry._();

  static BudgetsModule get module => AppLocator.get<BudgetsModule>();
}
