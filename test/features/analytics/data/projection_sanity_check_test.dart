import 'package:finaper/features/analytics/data/analytics_engine.dart';
import 'package:finaper/features/analytics/domain/entities/month_projection_entity.dart';
import 'package:finaper/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

// April 2026 — past month: daysElapsed = totalDays (30) → reliability = high.
final _april = DateTime(2026, 4, 1);

// May 2026 — used with injected today for deterministic current-month tests.
final _may = DateTime(2026, 5, 1);

TransactionEntity _income(double amount, DateTime date) => TransactionEntity(
      description: 'ingreso',
      category: 'Sueldo',
      amount: amount,
      isIncome: true,
      date: date,
      createdAt: date,
      note: '',
    );

TransactionEntity _expense(double amount, DateTime date) => TransactionEntity(
      description: 'gasto',
      category: 'Varios',
      amount: amount,
      isIncome: false,
      date: date,
      createdAt: date,
      note: '',
    );

MonthProjectionEntity _entity({
  required ProjectionReliability reliability,
  required bool isSanityFailed,
}) =>
    MonthProjectionEntity(
      currentExpense: 0,
      projectedExpense: 0,
      currentIncome: 0,
      projectedIncome: 0,
      projectedNetFlow: 0,
      daysElapsed: 24,
      totalDays: 31,
      reliability: reliability,
      budgetsAtRisk: [],
      isSanityFailed: isSanityFailed,
    );

void main() {
  group('showProjectedAmounts — isSanityFailed ya no bloquea —', () {
    test(
        '1. reliability=high + isSanityFailed=true → showProjectedAmounts=true',
        () {
      final e = _entity(
          reliability: ProjectionReliability.high, isSanityFailed: true);
      expect(e.showProjectedAmounts, isTrue);
    });

    test(
        '2. isSanityFailed accesible en entidad (badge y mensaje dependen de él)',
        () {
      final e = _entity(
          reliability: ProjectionReliability.high, isSanityFailed: true);
      expect(e.isSanityFailed, isTrue);
    });

    test(
        '3. reliability=medium + isSanityFailed=true → showProjectedAmounts=true',
        () {
      final e = _entity(
          reliability: ProjectionReliability.medium, isSanityFailed: true);
      expect(e.showProjectedAmounts, isTrue);
    });

    test(
        '4. reliability=low + isSanityFailed=false → showProjectedAmounts=false',
        () {
      final e = _entity(
          reliability: ProjectionReliability.low, isSanityFailed: false);
      expect(e.showProjectedAmounts, isFalse);
    });

    test(
        '4b. reliability=low + isSanityFailed=true → showProjectedAmounts=false '
        '(low reliability gana sobre sanity)',
        () {
      final e = _entity(
          reliability: ProjectionReliability.low, isSanityFailed: true);
      expect(e.showProjectedAmounts, isFalse);
    });
  });

  group('AnalyticsEngine.buildProjection — fecha determinística vía today —',
      () {
    // May 2026: 31 days total.

    test('1. día 24 + isSanityFailed=true → showProjectedAmounts=true', () {
      final today = DateTime(2026, 5, 24);
      final txs = [
        // Historical income: 1M/mes (Feb–Apr) → avg = 1M
        _income(1000000, DateTime(2026, 2, 15)),
        _income(1000000, DateTime(2026, 3, 15)),
        _income(1000000, DateTime(2026, 4, 15)),
        // Mayo: 4M → projectedIncome = 4M > avg*3=3M → sanity falla
        _income(4000000, DateTime(2026, 5, 10)),
        _expense(500000, DateTime(2026, 5, 15)),
      ];

      final result = AnalyticsEngine.buildProjection(
        transactions: txs,
        budgets: [],
        month: _may,
        today: today,
      );

      expect(result.isSanityFailed, isTrue);
      expect(result.showProjectedAmounts, isTrue);
    });

    test('2. día 24 → reliability=high', () {
      final result = AnalyticsEngine.buildProjection(
        transactions: [],
        budgets: [],
        month: _may,
        today: DateTime(2026, 5, 24),
      );

      expect(result.reliability, ProjectionReliability.high);
      expect(result.daysElapsed, 24);
    });

    test('3. día 24 → projectedExpense usa factor totalDays / daysElapsed', () {
      // factor = 31/24; expense de 240000 → projected = 240000 * 31/24 = 310000
      final txs = [_expense(240000, DateTime(2026, 5, 10))];

      final result = AnalyticsEngine.buildProjection(
        transactions: txs,
        budgets: [],
        month: _may,
        today: DateTime(2026, 5, 24),
      );

      final expectedFactor = 31 / 24;
      expect(result.projectedExpense,
          closeTo(240000 * expectedFactor, 0.01));
    });

    test('4. día 24 → projectedIncome == currentIncome (sin extrapolación)', () {
      final txs = [_income(800000, DateTime(2026, 5, 5))];

      final result = AnalyticsEngine.buildProjection(
        transactions: txs,
        budgets: [],
        month: _may,
        today: DateTime(2026, 5, 24),
      );

      expect(result.projectedIncome, equals(result.currentIncome));
      expect(result.projectedIncome, equals(800000));
    });

    test('5. día 8 → reliability=low y showProjectedAmounts=false', () {
      final result = AnalyticsEngine.buildProjection(
        transactions: [_expense(100000, DateTime(2026, 5, 5))],
        budgets: [],
        month: _may,
        today: DateTime(2026, 5, 8),
      );

      expect(result.reliability, ProjectionReliability.low);
      expect(result.showProjectedAmounts, isFalse);
      expect(result.daysElapsed, 8);
    });

    test('6. día 12 → reliability=medium y showProjectedAmounts=true', () {
      final result = AnalyticsEngine.buildProjection(
        transactions: [_expense(100000, DateTime(2026, 5, 5))],
        budgets: [],
        month: _may,
        today: DateTime(2026, 5, 12),
      );

      expect(result.reliability, ProjectionReliability.medium);
      expect(result.showProjectedAmounts, isTrue);
      expect(result.daysElapsed, 12);
    });

    test('7. día 16+ → reliability=high y showProjectedAmounts=true', () {
      final result = AnalyticsEngine.buildProjection(
        transactions: [_expense(100000, DateTime(2026, 5, 10))],
        budgets: [],
        month: _may,
        today: DateTime(2026, 5, 16),
      );

      expect(result.reliability, ProjectionReliability.high);
      expect(result.showProjectedAmounts, isTrue);
      expect(result.daysElapsed, 16);
    });
  });

  group('AnalyticsEngine.buildProjection — sanity check integración —', () {
    test(
        '5. ingreso 4× el histórico → isSanityFailed=true pero showProjectedAmounts=true',
        () {
      final txs = [
        _income(1000000, DateTime(2026, 1, 15)),
        _income(1000000, DateTime(2026, 2, 15)),
        _income(1000000, DateTime(2026, 3, 15)),
        _income(4000000, DateTime(2026, 4, 5)),
        _expense(500000, DateTime(2026, 4, 10)),
      ];

      final result = AnalyticsEngine.buildProjection(
        transactions: txs,
        budgets: [],
        month: _april,
      );

      expect(result.isSanityFailed, isTrue);
      expect(result.showProjectedAmounts, isTrue);
    });

    test('6. projectedIncome == currentIncome siempre (sin extrapolación)', () {
      final txs = [
        _income(800000, DateTime(2026, 4, 10)),
        _expense(300000, DateTime(2026, 4, 15)),
      ];

      final result = AnalyticsEngine.buildProjection(
        transactions: txs,
        budgets: [],
        month: _april,
      );

      expect(result.projectedIncome, equals(result.currentIncome));
      expect(result.projectedIncome, equals(800000));
    });

    test('7. sin historial previo → isSanityFailed=false aunque ingreso sea alto',
        () {
      final txs = [_income(10000000, DateTime(2026, 4, 5))];

      final result = AnalyticsEngine.buildProjection(
        transactions: txs,
        budgets: [],
        month: _april,
      );

      expect(result.isSanityFailed, isFalse);
    });

    test(
        '8. mes completo (factor=1) → projectedExpense == currentExpense',
        () {
      final txs = [
        _expense(600000, DateTime(2026, 4, 5)),
        _expense(400000, DateTime(2026, 4, 20)),
      ];

      final result = AnalyticsEngine.buildProjection(
        transactions: txs,
        budgets: [],
        month: _april,
      );

      // April: 30 days total, 30 elapsed → factor = 1
      expect(result.projectedExpense, equals(result.currentExpense));
      expect(result.currentExpense, equals(1000000));
    });
  });
}
