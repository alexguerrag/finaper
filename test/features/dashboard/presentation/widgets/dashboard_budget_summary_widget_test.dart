import 'package:finaper/app/di/app_locator.dart';
import 'package:finaper/core/theme/app_theme.dart';
import 'package:finaper/features/budgets/data/local/budgets_local_datasource.dart';
import 'package:finaper/features/budgets/data/models/budget_model.dart';
import 'package:finaper/features/budgets/di/budgets_module.dart';
import 'package:finaper/features/budgets/domain/entities/budget_entity.dart';
import 'package:finaper/features/budgets/domain/repositories/budgets_repository.dart';
import 'package:finaper/features/budgets/domain/usecases/get_budgets_by_month.dart';
import 'package:finaper/features/budgets/domain/usecases/upsert_budget.dart';
import 'package:finaper/features/dashboard/presentation/widgets/budget_alert_banner_widget.dart';
import 'package:finaper/features/settings/di/settings_module.dart';
import 'package:finaper/features/settings/domain/entities/app_settings_entity.dart';
import 'package:finaper/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:finaper/features/settings/domain/usecases/get_app_settings.dart';
import 'package:finaper/features/settings/domain/usecases/save_app_settings.dart';
import 'package:finaper/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeBudgetsRepository budgetsRepository;

  setUp(() async {
    AppLocator.clear();

    final settingsModule = _TestSettingsModule();
    await settingsModule.register();
    AppLocator.register<SettingsModule>(settingsModule);

    budgetsRepository = _FakeBudgetsRepository();

    final budgetsModule = _TestBudgetsModule(
      repository: budgetsRepository,
    );
    await budgetsModule.register();
    AppLocator.register<BudgetsModule>(budgetsModule);
  });

  tearDown(() {
    AppLocator.clear();
  });

  group('BudgetAlertBannerWidget', () {
    testWidgets(
      'no renderiza nada cuando no hay presupuestos en riesgo',
      (tester) async {
        budgetsRepository.itemsByMonth['2026-04'] = [
          _budget(
            id: 'b1',
            categoryId: 'food',
            categoryName: 'Alimentación',
            amountLimit: 100,
            spentAmount: 30,
            color: Colors.orange.withValues(alpha: 1.0),
            monthKey: '2026-04',
          ),
        ];

        await tester.pumpWidget(
          _buildTestableWidget(
            child: BudgetAlertBannerWidget(
              month: DateTime(2026, 4, 1),
              refreshToken: 0,
              onManagePressed: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Alerta de presupuesto'), findsNothing);
        expect(find.text('Presupuesto excedido'), findsNothing);
      },
    );

    testWidgets(
      'renderiza alerta del mes seleccionado cuando hay presupuesto en riesgo',
      (tester) async {
        budgetsRepository.itemsByMonth['2026-04'] = [
          _budget(
            id: 'b1',
            categoryId: 'food',
            categoryName: 'Alimentación',
            amountLimit: 100,
            spentAmount: 85,
            color: Colors.orange.withValues(alpha: 1.0),
            monthKey: '2026-04',
          ),
        ];

        await tester.pumpWidget(
          _buildTestableWidget(
            child: BudgetAlertBannerWidget(
              month: DateTime(2026, 4, 1),
              refreshToken: 0,
              onManagePressed: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Alerta de presupuesto'), findsOneWidget);
        expect(find.textContaining('Alimentación al 85%'), findsOneWidget);
        expect(find.text('Ver'), findsOneWidget);
      },
    );

    testWidgets(
      'se actualiza cuando cambia el mes seleccionado',
      (tester) async {
        budgetsRepository.itemsByMonth['2026-04'] = [
          _budget(
            id: 'b1',
            categoryId: 'food',
            categoryName: 'Alimentación',
            amountLimit: 100,
            spentAmount: 85,
            color: Colors.orange.withValues(alpha: 1.0),
            monthKey: '2026-04',
          ),
        ];

        budgetsRepository.itemsByMonth['2026-03'] = [
          _budget(
            id: 'b2',
            categoryId: 'transport',
            categoryName: 'Transporte',
            amountLimit: 100,
            spentAmount: 95,
            color: Colors.blue.withValues(alpha: 1.0),
            monthKey: '2026-03',
          ),
        ];

        await tester.pumpWidget(
          _buildTestableWidget(
            child: BudgetAlertBannerWidget(
              month: DateTime(2026, 4, 1),
              refreshToken: 0,
              onManagePressed: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.textContaining('Alimentación al 85%'), findsOneWidget);

        await tester.pumpWidget(
          _buildTestableWidget(
            child: BudgetAlertBannerWidget(
              month: DateTime(2026, 3, 1),
              refreshToken: 0,
              onManagePressed: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.textContaining('Transporte al 95%'), findsOneWidget);
        expect(find.textContaining('Alimentación al 85%'), findsNothing);
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

BudgetEntity _budget({
  required String id,
  required String categoryId,
  required String categoryName,
  required double amountLimit,
  required double spentAmount,
  required Color color,
  required String monthKey,
}) {
  return BudgetEntity(
    id: id,
    categoryId: categoryId,
    categoryName: categoryName,
    monthKey: monthKey,
    amountLimit: amountLimit,
    spentAmount: spentAmount,
    color: color,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

class _TestBudgetsModule extends BudgetsModule {
  _TestBudgetsModule({
    required BudgetsRepository repository,
  })  : _repository = repository,
        super();

  final BudgetsRepository _repository;

  @override
  Future<void> register() async {
    localDataSource = _UnsupportedBudgetsLocalDataSource();
    repository = _repository;
    getBudgetsByMonth = GetBudgetsByMonth(_repository);
    upsertBudget = UpsertBudget(_repository);
  }
}

class _FakeBudgetsRepository implements BudgetsRepository {
  final Map<String, List<BudgetEntity>> itemsByMonth = {};

  @override
  Future<List<BudgetEntity>> getBudgetsByMonth({
    required String monthKey,
  }) async {
    return itemsByMonth[monthKey] ?? <BudgetEntity>[];
  }

  @override
  Future<BudgetEntity> upsertBudget(BudgetEntity budget) async {
    final current =
        List<BudgetEntity>.from(itemsByMonth[budget.monthKey] ?? []);
    current.removeWhere((item) => item.categoryId == budget.categoryId);
    current.add(budget);
    itemsByMonth[budget.monthKey] = current;
    return budget;
  }

  @override
  Future<void> deleteBudget(String id) async {
    for (final key in itemsByMonth.keys) {
      itemsByMonth[key]?.removeWhere((item) => item.id == id);
    }
  }
}

class _UnsupportedBudgetsLocalDataSource implements BudgetsLocalDataSource {
  @override
  Future<List<BudgetModel>> getBudgetsByMonth({
    required String monthKey,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BudgetModel> upsertBudget(BudgetModel budget) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteBudget(String id) {
    throw UnimplementedError();
  }
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
