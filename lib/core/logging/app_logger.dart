import 'package:flutter/foundation.dart';

/// Logger centralizado para reducir `debugPrint` disperso y
/// preparar una estrategia consistente por capa.
abstract final class AppLogger {
  static void info(String scope, String message) {
    debugPrint('[INFO][$scope] $message');
  }

  static void warning(String scope, String message) {
    debugPrint('[WARN][$scope] $message');
  }

  static void error(
    String scope,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('[ERROR][$scope] $message');
    if (error != null) {
      debugPrint('[ERROR][$scope] cause: $error');
    }
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
