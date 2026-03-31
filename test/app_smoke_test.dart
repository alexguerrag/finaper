import 'package:finaper/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FinaperApp smoke test', () {
    testWidgets('renderiza la pantalla inicial correctamente', (tester) async {
      await tester.pumpWidget(const FinaperApp());
      await tester.pumpAndSettle();

      expect(find.text('Finaper'), findsOneWidget);
      expect(find.text('Entrar a la app'), findsOneWidget);
      expect(find.text('Dashboard financiero'), findsOneWidget);
      expect(find.text('Registro de transacciones'), findsOneWidget);

      final scrollable = find.byType(Scrollable);
      final localModeButton = find.text('Continuar en modo local');

      await tester.scrollUntilVisible(
        localModeButton,
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(localModeButton, findsOneWidget);
    });
  });
}
