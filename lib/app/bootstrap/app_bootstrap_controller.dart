import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../features/budgets/di/budgets_module.dart';
import '../../features/goals/di/goals_module.dart';
import '../../features/recurring_transactions/di/recurring_transactions_module.dart';
import '../../features/settings/di/settings_module.dart';
import '../../features/transactions/di/transactions_module.dart';
import '../di/app_composer.dart';
import '../di/app_locator.dart';
import '../di/app_registry.dart';
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
      AppLogger.info('bootstrap', 'Registering app modules');

      AppRegistry.clear();
      AppLocator.clear();

      final settingsModule = SettingsModule();
      final transactionsModule = TransactionsModule();
      final budgetsModule = BudgetsModule();
      final goalsModule = GoalsModule();
      final recurringTransactionsModule = RecurringTransactionsModule();

      AppRegistry.registerModule(settingsModule);
      AppRegistry.registerModule(transactionsModule);
      AppRegistry.registerModule(budgetsModule);
      AppRegistry.registerModule(goalsModule);
      AppRegistry.registerModule(recurringTransactionsModule);

      AppLocator.register<SettingsModule>(settingsModule);
      AppLocator.register<TransactionsModule>(transactionsModule);
      AppLocator.register<BudgetsModule>(budgetsModule);
      AppLocator.register<GoalsModule>(goalsModule);
      AppLocator.register<RecurringTransactionsModule>(
          recurringTransactionsModule);

      final composer = AppComposer();
      await composer.compose();

      await settingsModule.controller.load();

      _status = BootstrapStatus.ready;
      AppLogger.info('bootstrap', 'Application modules ready');
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
