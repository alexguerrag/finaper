import 'package:finaper/app/di/app_locator.dart';
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
      'renderiza mes, ingresos y gastos',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(
            child: DashboardFinancialSnapshotWidget(
              monthLabel: 'abril de 2026',
              netFlow: 100,
              income: 130,
              expense: 30,
              canGoToNextMonth: false,
              onPreviousMonth: () {},
              onNextMonth: () {},
              onOpenTransactions: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('abril de 2026'), findsOneWidget);
        expect(find.text('Ingresos'), findsOneWidget);
        expect(find.text('Gastos'), findsOneWidget);
        expect(find.textContaining('130'), findsWidgets);
        expect(find.textContaining('30'), findsWidgets);
      },
    );

    testWidgets(
      'ejecuta callback de mes anterior',
      (tester) async {
        var previousMonthTapped = 0;

        await tester.pumpWidget(
          _buildTestableWidget(
            child: DashboardFinancialSnapshotWidget(
              monthLabel: 'abril de 2026',
              netFlow: 100,
              income: 130,
              expense: 30,
              canGoToNextMonth: true,
              onPreviousMonth: () {
                previousMonthTapped++;
              },
              onNextMonth: () {},
              onOpenTransactions: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.chevron_left_rounded));
        await tester.pump();

        expect(previousMonthTapped, 1);
      },
    );

    testWidgets(
      'deshabilita navegación al siguiente mes cuando no corresponde',
      (tester) async {
        var nextMonthTapped = 0;

        await tester.pumpWidget(
          _buildTestableWidget(
            child: DashboardFinancialSnapshotWidget(
              monthLabel: 'abril de 2026',
              netFlow: 100,
              income: 130,
              expense: 30,
              canGoToNextMonth: false,
              onPreviousMonth: () {},
              onNextMonth: () {
                nextMonthTapped++;
              },
              onOpenTransactions: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.chevron_right_rounded));
        await tester.pump();

        expect(nextMonthTapped, 0);
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
