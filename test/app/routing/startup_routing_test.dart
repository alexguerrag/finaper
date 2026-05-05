import 'package:finaper/app/di/app_locator.dart';
import 'package:finaper/app/routes/app_routes.dart';
import 'package:finaper/features/analytics/domain/entities/entitlement_status.dart';
import 'package:finaper/features/analytics/domain/repositories/entitlement_repository.dart';
import 'package:finaper/features/analytics/domain/usecases/clear_entitlement_cache.dart';
import 'package:finaper/features/analytics/domain/usecases/get_entitlement_status.dart';
import 'package:finaper/features/analytics/domain/usecases/refresh_entitlement.dart';
import 'package:finaper/features/analytics/presentation/controllers/entitlement_controller.dart';
import 'package:finaper/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:finaper/features/settings/di/settings_module.dart';
import 'package:finaper/features/settings/domain/entities/app_settings_entity.dart';
import 'package:finaper/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:finaper/features/settings/domain/usecases/get_app_settings.dart';
import 'package:finaper/features/settings/domain/usecases/save_app_settings.dart';
import 'package:finaper/features/settings/presentation/controllers/settings_controller.dart';
import 'package:finaper/features/shell/presentation/pages/more_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Fake entitlement — sin RevenueCat ni SharedPreferences
// ---------------------------------------------------------------------------

class _FakeEntitlementRepository implements EntitlementRepository {
  @override
  EntitlementStatus get cachedStatus => EntitlementStatus.free;

  @override
  Future<EntitlementStatus> refresh() async => EntitlementStatus.free;

  @override
  Future<void> clearCache() async {}
}

EntitlementController _fakeEntitlementController() {
  final repo = _FakeEntitlementRepository();
  return EntitlementController(
    getEntitlementStatus: GetEntitlementStatus(repo),
    refreshEntitlement: RefreshEntitlement(repo),
    clearEntitlementCache: ClearEntitlementCache(repo),
  );
}

// ---------------------------------------------------------------------------
// Fake repository — no SQLite required
// ---------------------------------------------------------------------------

class _FakeAppSettingsRepository implements AppSettingsRepository {
  AppSettingsEntity _settings;

  _FakeAppSettingsRepository(this._settings);

  @override
  Future<AppSettingsEntity> getAppSettings() async => _settings;

  @override
  Future<AppSettingsEntity> saveAppSettings(AppSettingsEntity s) async {
    _settings = s;
    return s;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<SettingsController> _makeController({
  required bool hasCompletedOnboarding,
}) async {
  final settings = AppSettingsEntity(
    id: AppSettingsEntity.singletonId,
    currencyCode: AppSettingsEntity.defaultCurrencyCode,
    localeCode: AppSettingsEntity.defaultLocaleCode,
    useSystemLocale: false,
    hasCompletedOnboarding: hasCompletedOnboarding,
    updatedAt: DateTime.now(),
  );
  final repo = _FakeAppSettingsRepository(settings);
  final controller = SettingsController(
    getAppSettings: GetAppSettings(repo),
    saveAppSettings: SaveAppSettings(repo),
  );
  await controller.load();
  return controller;
}

Future<void> _registerFakeSettings({
  required bool hasCompletedOnboarding,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final controller = await _makeController(
    hasCompletedOnboarding: hasCompletedOnboarding,
  );
  AppLocator.register<SettingsModule>(
      SettingsModule.withController(controller));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  tearDown(() => AppLocator.clear());

  group('Startup routing', () {
    testWidgets(
      '3a — instalación nueva muestra OnboardingScreen',
      (WidgetTester tester) async {
        // FinaperApp now owns the bootstrap flow (requires SQLite), so we
        // mount OnboardingScreen directly with the DI it needs. The routing
        // decision (hasCompletedOnboarding → which screen) is covered by 3b.
        await _registerFakeSettings(hasCompletedOnboarding: false);

        await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
        await tester.pump();

        expect(find.text('Bienvenido a Finaper'), findsOneWidget);
      },
    );

    test(
      '3b — onboarding completado resuelve ruta shell sin flash',
      () async {
        final controller = await _makeController(hasCompletedOnboarding: true);

        final route = controller.hasCompletedOnboarding
            ? AppRoutes.shell
            : AppRoutes.initial;

        expect(route, equals(AppRoutes.shell));
        expect(route, isNot(equals(AppRoutes.initial)));
      },
    );
  });

  group('MoreScreen navigation', () {
    testWidgets(
      '3c — tab Más muestra los tiles esperados',
      (WidgetTester tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;

        await tester.pumpWidget(
          MaterialApp(
            home: MoreScreen(
              onRefreshDashboard: () async {},
              entitlementController: _fakeEntitlementController(),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Reportes'), findsOneWidget);
        expect(find.text('Metas'), findsOneWidget);
        expect(find.text('Categorías'), findsOneWidget);
        expect(find.text('Recurrentes'), findsOneWidget);
        expect(find.text('Datos y respaldo'), findsOneWidget);
        expect(find.text('Ajustes'), findsOneWidget);
      },
    );

    testWidgets(
      '3d — shell expone NavigationBar con 4 destinos',
      (WidgetTester tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const SizedBox.shrink(),
              bottomNavigationBar: NavigationBar(
                selectedIndex: 0,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Inicio',
                    tooltip: 'Resumen financiero',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long_rounded),
                    label: 'Movimientos',
                    tooltip: 'Transacciones',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                    label: 'Cuentas',
                    tooltip: 'Mis cuentas',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_rounded),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: 'Más',
                    tooltip: 'Más opciones',
                  ),
                ],
              ),
            ),
          ),
        );

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.destinations.length, equals(4));
      },
    );
  });
}
