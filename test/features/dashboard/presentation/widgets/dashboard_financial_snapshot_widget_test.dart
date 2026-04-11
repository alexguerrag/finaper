import 'package:finaper/app/di/app_locator.dart';
import 'package:finaper/core/formatters/app_formatters.dart';
import 'package:finaper/core/theme/app_theme.dart';
import 'package:finaper/features/dashboard/presentation/widgets/dashboard_financial_snapshot_widget.dart';
import 'package:finaper/features/settings/di/settings_module.dart';
import 'package:finaper/features/settings/domain/entities/app_settings_entity.dart';
import 'package:finaper/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:finaper/features/settings/domain/usecases/get_app_settings.dart';
import 'package:finaper/features/settings/domain/usecases/save_app_settings.dart';
import 'package:finaper/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    AppLocator.clear();

    final settingsModule = _TestSettingsModule();
    await settingsModule.register();
    AppLocator.register<SettingsModule>(settingsModule);
  });

  tearDownAll(() {
    AppLocator.clear();
  });

  group('DashboardFinancialSnapshotWidget', () {
    testWidgets(
      'renderiza saldo total y métricas del mes',
      (tester) async {
        final formattedBalance = AppFormatters.formatCurrency(1380);
        final formattedExpense = AppFormatters.formatCurrency(120);
        final formattedZero = AppFormatters.formatCurrency(0);

        await tester.pumpWidget(
          _buildTestableWidget(
            child: DashboardFinancialSnapshotWidget(
              monthLabel: 'abril de 2026',
              consolidatedBalance: 1380,
              netFlow: -120,
              income: 0,
              expense: 120,
              canGoToNextMonth: false,
              onPreviousMonth: () {},
              onNextMonth: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('abril de 2026'), findsOneWidget);
        expect(find.text('Saldo total'), findsOneWidget);
        expect(find.text('Flujo del mes'), findsOneWidget);
        expect(find.text('Ingresos'), findsOneWidget);
        expect(find.text('Gastos'), findsOneWidget);

        expect(find.text(formattedBalance), findsOneWidget);
        expect(find.text('-$formattedExpense'), findsOneWidget);
        expect(find.text(formattedZero), findsOneWidget);
        expect(find.text(formattedExpense), findsOneWidget);
      },
    );
  });
}

Widget _buildTestableWidget({
  required Widget child,
}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

class _TestSettingsModule extends SettingsModule {
  _TestSettingsModule() : super();

  @override
  Future<void> register() async {
    final repository = _FakeAppSettingsRepository();

    getAppSettings = GetAppSettings(repository);
    saveAppSettings = SaveAppSettings(repository);
    controller = SettingsController(
      getAppSettings: getAppSettings,
      saveAppSettings: saveAppSettings,
    );
  }
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  AppSettingsEntity _settings = AppSettingsEntity.defaults();

  @override
  Future<AppSettingsEntity> getAppSettings() async {
    return _settings;
  }

  @override
  Future<AppSettingsEntity> saveAppSettings(
    AppSettingsEntity settings,
  ) async {
    _settings = settings;
    return _settings;
  }
}
