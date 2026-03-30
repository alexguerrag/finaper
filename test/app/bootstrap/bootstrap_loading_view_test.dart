import 'package:finaper/app/bootstrap/bootstrap_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BootstrapLoadingView renders expected content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BootstrapLoadingView(),
      ),
    );

    expect(find.text('Inicializando Finaper'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
