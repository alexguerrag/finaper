import 'package:finaper/app/app.dart';
import 'package:finaper/app/di/app_locator.dart';
import 'package:finaper/features/settings/di/settings_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final settingsModule = SettingsModule();
    await settingsModule.register();
    AppLocator.clear();
    AppLocator.register<SettingsModule>(settingsModule);
  });

  tearDownAll(() {
    AppLocator.clear();
  });

  group('FinaperApp smoke test', () {
    testWidgets('renderiza la pantalla inicial correctamente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const FinaperApp());
      await tester.pumpAndSettle();

      expect(find.text('Finaper'), findsOneWidget);
    });
  });
}
