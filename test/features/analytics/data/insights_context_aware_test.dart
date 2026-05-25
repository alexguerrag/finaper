import 'package:finaper/features/analytics/data/analytics_engine.dart';
import 'package:finaper/features/analytics/domain/entities/analytics_insight_entity.dart';
import 'package:finaper/features/analytics/domain/entities/monthly_comparison_entity.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CategoryDelta _delta({
  required String name,
  required double previous,
  required double current,
}) {
  final pct = previous > 0 ? (current - previous) / previous * 100 : 0.0;
  return CategoryDelta(
    categoryName: name,
    currentAmount: current,
    previousAmount: previous,
    deltaPercent: pct,
  );
}

MonthlyComparisonEntity _comparison({
  List<CategoryDelta> topRising = const [],
  List<CategoryDelta> topFalling = const [],
  double netFlowDelta = 0,
  double previousIncome = 0,
  double incomeDelta = 0,
}) =>
    MonthlyComparisonEntity(
      hasPreviousMonthData: true,
      currentIncome: 0,
      currentExpense: 0,
      currentNetFlow: 0,
      previousIncome: previousIncome,
      previousExpense: 0,
      previousNetFlow: 0,
      incomeDelta: incomeDelta,
      expenseDelta: 0,
      netFlowDelta: netFlowDelta,
      topRising: topRising,
      topFalling: topFalling,
    );

List<AnalyticsInsightEntity> _run(MonthlyComparisonEntity comparison) =>
    AnalyticsEngine.buildInsights(
      comparison: comparison,
      transactions: const [],
      month: DateTime(2026, 5, 1),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('buildInsights — filtro por diferencia absoluta —', () {
    test(
        '1. previousAmount bajo + deltaPercent extremo + absoluteDelta bajo '
        '→ no genera insight', () {
      // Salud: anterior $342, actual $3.991 → delta $3.649 < $10.000
      final insights = _run(_comparison(
        topRising: [_delta(name: 'Salud', previous: 342, current: 3991)],
      ));
      expect(insights.where((i) => i.message.contains('Salud')), isEmpty);
    });

    test('2. previousAmount bajo + absoluteDelta bajo → no genera insight', () {
      // Caso 4 del documento: anterior $5.000, actual $13.000, delta $8.000
      final insights = _run(_comparison(
        topRising: [_delta(name: 'Hogar', previous: 5000, current: 13000)],
      ));
      expect(insights.where((i) => i.message.contains('Hogar')), isEmpty);
    });

    test(
        '3. previousAmount suficiente + absoluteDelta suficiente + deltaPercent normal '
        '→ insight con porcentaje', () {
      // anterior $50.000, actual $75.000, delta $25.000, +50%
      final insights = _run(_comparison(
        topRising: [_delta(name: 'Casa', previous: 50000, current: 75000)],
      ));
      final msg = insights
          .firstWhere((i) => i.message.contains('Casa'))
          .message;
      expect(msg, contains('50%'));
      expect(msg, contains('frente al mismo periodo del mes anterior'));
    });

    test(
        '4. deltaPercent > 300 + monto relevante '
        '→ insight cualitativo sin número exacto', () {
      // anterior $50.000, actual $250.000, delta $200.000, +400%
      final insights = _run(_comparison(
        topRising: [_delta(name: 'Casa', previous: 50000, current: 250000)],
      ));
      final msg = insights
          .firstWhere((i) => i.message.contains('Casa'))
          .message;
      expect(msg, contains('aumentó fuertemente'));
      expect(msg, isNot(contains('400%')));
      expect(msg, contains('Revisa si fue un gasto puntual'));
    });

    test(
        '5. previousAmount < 20K + absoluteDelta suficiente '
        '→ insight cualitativo (base baja)', () {
      // anterior $5.000, actual $50.000, delta $45.000 → base baja → cualitativo
      final insights = _run(_comparison(
        topRising: [_delta(name: 'Salud', previous: 5000, current: 50000)],
      ));
      final msg = insights
          .firstWhere((i) => i.message.contains('Salud'))
          .message;
      expect(msg, contains('aumentó fuertemente'));
      expect(msg, isNot(contains('%')));
    });

    test(
        '6. deltaPercent negativo normal → insight de baja con porcentaje', () {
      // anterior $80.000, actual $55.000, delta -$25.000, -31%
      final insights = _run(_comparison(
        topFalling: [_delta(name: 'Transporte', previous: 80000, current: 55000)],
      ));
      final msg = insights
          .firstWhere((i) => i.message.contains('Transporte'))
          .message;
      expect(msg, contains('bajó'));
      expect(msg, contains('31%'));
      expect(msg, contains('frente al mismo periodo del mes anterior'));
    });

    test(
        '7. baja con previousAmount bajo + absoluteDelta suficiente '
        '→ insight cualitativo sin porcentaje', () {
      // anterior $5.000, actual $0, delta -$5.000 — absoluteDelta = 5K < 10K → NO insight
      // Probamos con delta suficiente: anterior $5.000, actual $0 → -$5.000 < 10K → no insight
      // Para baja cualitativa necesitamos: prev < 20K Y absoluteDelta >= 10K
      // anterior $15.000, actual $0, delta -$15.000
      final insights = _run(_comparison(
        topFalling: [
          _delta(name: 'Restaurantes', previous: 15000, current: 0),
        ],
      ));
      // deltaPercent = -100 (eliminated), absoluteDelta = 15K >= 10K → pasa filtro
      // previousAmount = 15K < 20K → cualitativo
      final msg = insights
          .firstWhere((i) => i.message.contains('Restaurantes'))
          .message;
      expect(msg, contains('bajó'));
      expect(msg, isNot(contains('%')));
    });

    test(
        '8. baja con absoluteDelta bajo → no genera insight', () {
      // anterior $8.000, actual $0, delta -$8.000 < $10.000
      final insights = _run(_comparison(
        topFalling: [_delta(name: 'Ocio', previous: 8000, current: 0)],
      ));
      expect(insights.where((i) => i.message.contains('Ocio')), isEmpty);
    });
  });

  group('buildInsights — copy "frente al mismo periodo" —', () {
    test('7. ningún insight contiene "respecto al mes pasado"', () {
      final insights = _run(_comparison(
        topRising: [_delta(name: 'Casa', previous: 50000, current: 75000)],
        topFalling: [
          _delta(name: 'Transporte', previous: 80000, current: 55000)
        ],
        netFlowDelta: 10000,
        previousIncome: 100000,
        incomeDelta: 40000,
      ));
      for (final i in insights) {
        expect(
          i.message,
          isNot(contains('respecto al mes pasado')),
          reason: 'mensaje incorrecto: "${i.message}"',
        );
      }
    });

    test('8. insights de categoría contienen "frente al mismo periodo"', () {
      final insights = _run(_comparison(
        topRising: [_delta(name: 'Casa', previous: 50000, current: 75000)],
        topFalling: [
          _delta(name: 'Transporte', previous: 80000, current: 55000)
        ],
      ));
      final catInsights = insights
          .where((i) =>
              i.message.contains('Casa') || i.message.contains('Transporte'))
          .toList();
      expect(catInsights, isNotEmpty);
      for (final i in catInsights) {
        expect(i.message, contains('frente al mismo periodo'));
      }
    });

    test('9. netFlowDelta positivo → copy actualizado', () {
      final insights = _run(_comparison(netFlowDelta: 5000));
      final msg = insights
          .firstWhere((i) => i.message.contains('ahorro'))
          .message;
      expect(msg, contains('frente al mismo periodo del mes anterior'));
      expect(msg, contains('mejoró'));
    });

    test('10. netFlowDelta negativo → copy actualizado', () {
      final insights = _run(_comparison(netFlowDelta: -5000));
      final msg = insights
          .firstWhere((i) => i.message.contains('ahorro'))
          .message;
      expect(msg, contains('frente al mismo periodo del mes anterior'));
      expect(msg, contains('menor'));
    });

    test('11. variación de ingresos > 30% → copy actualizado', () {
      // incomeDelta = 35% de previousIncome = 100K → delta = 35K > 30%
      final insights = _run(_comparison(
        previousIncome: 100000,
        incomeDelta: 35000,
      ));
      final msg = insights
          .firstWhere((i) => i.message.contains('ingresos'))
          .message;
      expect(msg, contains('frente al mismo periodo del mes anterior'));
    });
  });

  group('buildInsights — sin datos del mes anterior —', () {
    test('no genera insights de comparación cuando hasPreviousMonthData=false',
        () {
      final insights = AnalyticsEngine.buildInsights(
        comparison: MonthlyComparisonEntity(
          hasPreviousMonthData: false,
          currentIncome: 200000,
          currentExpense: 150000,
          currentNetFlow: 50000,
          previousIncome: 0,
          previousExpense: 0,
          previousNetFlow: 0,
          incomeDelta: 0,
          expenseDelta: 0,
          netFlowDelta: 0,
          topRising: const [],
          topFalling: const [],
        ),
        transactions: const [],
        month: DateTime(2026, 5, 1),
      );
      // Solo puede aparecer el de cuenta con mayor salida (no requiere datos previos)
      expect(
        insights.where((i) => i.message.contains('frente al mismo periodo')),
        isEmpty,
      );
    });
  });
}
