import '../../../app/di/app_locator.dart';
import 'analytics_module.dart';

class AnalyticsRegistry {
  AnalyticsRegistry._();

  static AnalyticsModule get module => AppLocator.get<AnalyticsModule>();
}
