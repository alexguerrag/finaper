import 'package:flutter/foundation.dart';

@Deprecated(
  'AppServices quedó en modo compatibilidad. Usa módulos + registry/locator.',
)
class AppServices {
  AppServices._();

  static final AppServices instance = AppServices._();

  Future<void> initialize() async {
    try {
      debugPrint(
        'AppServices.initialize() está deprecado. '
        'La inicialización ahora ocurre en AppBootstrapController mediante módulos.',
      );
    } catch (e, s) {
      debugPrint('AppServices.initialize compatibility error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
