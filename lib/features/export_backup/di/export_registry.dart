import '../../../app/di/app_locator.dart';

import 'export_module.dart';

class ExportRegistry {
  ExportRegistry._();

  static ExportModule get module => AppLocator.get<ExportModule>();
}
