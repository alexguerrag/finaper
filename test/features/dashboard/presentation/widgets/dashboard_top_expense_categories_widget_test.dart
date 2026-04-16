import 'package:finaper/app/di/app_locator.dart';
import 'package:finaper/core/theme/app_theme.dart';
import 'package:finaper/features/dashboard/data/local/dashboard_local_datasource.dart';
import 'package:finaper/features/dashboard/presentation/widgets/dashboard_top_expense_categories_widget.dart';
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

  group('DashboardTopExpenseCategoriesWidget', () {
    testWidgets(
      'renderiza estado vacío cuando no hay categorías',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const DashboardTopExpenseCategoriesWidget(
              categories: [],
              totalExpense: 0,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Distribución de gastos'), findsOneWidget);
        expect(find.text('No hay gastos registrados.'), findsOneWidget);
      },
    );

    testWidgets(
      'renderiza total y categorías con porcentaje y monto',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const DashboardTopExpenseCategoriesWidget(
              totalExpense: 30,
              categories: [
                DashboardExpenseCategorySummary(
                  categoryId: 'health',
                  categoryName: 'Salud',
                  amount: 20,
                  percentage: 0.67,
                  colorValue: 0xFF7E57C2,
                ),
                DashboardExpenseCategorySummary(
                  categoryId: 'food',
                  categoryName: 'Alimentación',
                  amount: 10,
                  percentage: 0.33,
                  colorValue: 0xFFFFB300,
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Distribución de gastos'), findsOneWidget);
        expect(find.text('Total gastado'), findsOneWidget);

        expect(find.text('Salud'), findsOneWidget);
        expect(find.text('Alimentación'), findsOneWidget);

        expect(find.text('67%'), findsOneWidget);
        expect(find.text('33%'), findsOneWidget);

        expect(find.textContaining('20'), findsWidgets);
        expect(find.textContaining('10'), findsWidgets);
        expect(find.textContaining('30'), findsWidgets);
      },
    );

    testWidgets(
      'ordena visualmente categorías según la lista recibida',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(
            child: const DashboardTopExpenseCategoriesWidget(
              totalExpense: 80,
              categories: [
                DashboardExpenseCategorySummary(
                  categoryId: 'transport',
                  categoryName: 'Transporte',
                  amount: 40,
                  percentage: 0.50,
                  colorValue: 0xFF42A5F5,
                ),
                DashboardExpenseCategorySummary(
                  categoryId: 'food',
                  categoryName: 'Alimentación',
                  amount: 20,
                  percentage: 0.25,
                  colorValue: 0xFFFFB300,
                ),
                DashboardExpenseCategorySummary(
                  categoryId: 'health',
                  categoryName: 'Salud',
                  amount: 20,
                  percentage: 0.25,
                  colorValue: 0xFF7E57C2,
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        final transportFinder = find.text('Transporte');
        final foodFinder = find.text('Alimentación');
        final healthFinder = find.text('Salud');

        expect(transportFinder, findsOneWidget);
        expect(foodFinder, findsOneWidget);
        expect(healthFinder, findsOneWidget);

        final transportTopLeft = tester.getTopLeft(transportFinder);
        final foodTopLeft = tester.getTopLeft(foodFinder);
        final healthTopLeft = tester.getTopLeft(healthFinder);

        expect(transportTopLeft.dy, lessThan(foodTopLeft.dy));
        expect(foodTopLeft.dy, lessThan(healthTopLeft.dy));
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
