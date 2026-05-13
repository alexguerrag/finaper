import 'package:finaper/features/analytics/presentation/helpers/savings_rate_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deltaBadgeText', () {
    test('delta pequeño positivo muestra puntos con signo +', () {
      final result = deltaBadgeText(4.2, true);
      expect(result, contains('puntos'));
      expect(result, contains('+'));
      expect(result, contains('4.2'));
      expect(result, isNot(contains('pp')));
    });

    test('delta pequeño negativo muestra puntos sin signo +', () {
      final result = deltaBadgeText(-8.1, true);
      expect(result, contains('puntos'));
      expect(result, contains('-8.1'));
      expect(result, isNot(contains('pp')));
    });

    test('delta extremo positivo higherIsGood=true muestra Mejoró sin número', () {
      final result = deltaBadgeText(2593.5, true);
      expect(result, equals('Mejoró vs mes anterior'));
      expect(result, isNot(contains('2593')));
    });

    test('delta extremo negativo higherIsGood=true muestra Bajó sin número', () {
      final result = deltaBadgeText(-200.0, true);
      expect(result, equals('Bajó vs mes anterior'));
      expect(result, isNot(contains('200')));
    });

    test('delta extremo positivo higherIsGood=false muestra Bajó', () {
      final result = deltaBadgeText(80.0, false);
      expect(result, equals('Bajó vs mes anterior'));
    });

    test('delta exactamente 50 muestra número (límite inferior del umbral)', () {
      final result = deltaBadgeText(50.0, true);
      expect(result, contains('puntos'));
      expect(result, contains('50.0'));
    });

    test('delta exactamente 50.1 muestra Mejoró (supera umbral)', () {
      final result = deltaBadgeText(50.1, true);
      expect(result, equals('Mejoró vs mes anterior'));
    });

    test('delta null-like: cero muestra puntos con signo +', () {
      final result = deltaBadgeText(0.0, true);
      expect(result, contains('puntos'));
      expect(result, contains('+0.0'));
    });
  });

  group('savingsRateMessage', () {
    test('rate positivo muestra mensaje de ahorro', () {
      final result = savingsRateMessage(18.5, '\$ 50.000');
      expect(result, contains('Ahorraste'));
      expect(result, contains('\$ 50.000'));
      expect(result, isNot(contains('Gastaste')));
      expect(result, isNot(contains('superaron')));
    });

    test('rate cero muestra mensaje de ahorro', () {
      final result = savingsRateMessage(0.0, '\$ 0');
      expect(result, contains('Ahorraste'));
    });

    test('rate negativo leve (abs <= 5) muestra mensaje de casi equilibrio', () {
      final result = savingsRateMessage(-0.4, '\$ 6.510');
      expect(result, contains('Gastaste'));
      expect(result, contains('equilibrio'));
      expect(result, isNot(contains('superaron')));
    });

    test('rate negativo exactamente -5 muestra mensaje de casi equilibrio', () {
      final result = savingsRateMessage(-5.0, '\$ 10.000');
      expect(result, contains('equilibrio'));
    });

    test('rate negativo alto (abs > 5) muestra mensaje de gastos superiores', () {
      final result = savingsRateMessage(-30.0, '\$ 80.000');
      expect(result, contains('superaron'));
      expect(result, isNot(contains('equilibrio')));
    });

    test('rate negativo -5.1 muestra mensaje de gastos superiores', () {
      final result = savingsRateMessage(-5.1, '\$ 15.000');
      expect(result, contains('superaron'));
    });
  });
}
