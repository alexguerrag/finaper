import 'package:finaper/app/bootstrap/bootstrap_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BootstrapErrorView renders message and retry action', (
    WidgetTester tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: BootstrapErrorView(
          message: 'Fallo controlado',
          onRetry: () async {
            retried = true;
          },
        ),
      ),
    );

    expect(find.text('Error al iniciar Finaper'), findsOneWidget);
    expect(find.text('Fallo controlado'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(retried, isTrue);
  });
}
