import '../../../app/di/app_locator.dart';

import 'categories_module.dart';

class CategoriesRegistry {
  CategoriesRegistry._();

  static CategoriesModule get module => AppLocator.get<CategoriesModule>();
}
