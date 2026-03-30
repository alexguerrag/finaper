import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/logging/app_logger.dart';
import '../di/app_services.dart';
import 'bootstrap_status.dart';

class AppBootstrapController extends ChangeNotifier {
  BootstrapStatus _status = BootstrapStatus.idle;
  String? _errorMessage;

  BootstrapStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isInitializing => _status == BootstrapStatus.initializing;
  bool get isReady => _status == BootstrapStatus.ready;
  bool get hasFailed => _status == BootstrapStatus.failure;

  Future<void> initialize() async {
    if (_status == BootstrapStatus.initializing) return;

    _status = BootstrapStatus.initializing;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.info('bootstrap', 'Initializing application services');
      await AppServices.instance.initialize();
      _status = BootstrapStatus.ready;
      AppLogger.info('bootstrap', 'Application services ready');
    } catch (error, stackTrace) {
      _status = BootstrapStatus.failure;
      _errorMessage =
          'No se pudo inicializar la aplicación. Intenta nuevamente.';
      AppLogger.error(
        'bootstrap',
        'Initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw BootstrapException(
        _errorMessage!,
        code: 'bootstrap_initialization_failed',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> retry() async {
    await initialize();
  }
}
