import '../../budgets/domain/entities/budget_entity.dart';
import '../../transactions/domain/entities/transaction_entity.dart';
import '../domain/entities/analytics_insight_entity.dart';
import '../domain/entities/cash_flow_entity.dart';
import '../domain/entities/ledger_entity.dart';
import '../domain/entities/month_projection_entity.dart';
import '../domain/entities/monthly_comparison_entity.dart';
import '../domain/entities/savings_rate_entity.dart';

class AnalyticsEngine {
  const AnalyticsEngine._();

  static MonthlyComparisonEntity buildComparison({
    required List<TransactionEntity> transactions,
    required DateTime month,
  }) {
    final currentStart = DateTime(month.year, month.month, 1);
    final currentEnd = DateTime(month.year, month.month + 1, 1);
    // Dart normalises month=0 → December of previous year automatically.
    final previousStart = DateTime(month.year, month.month - 1, 1);
    final previousEnd = currentStart;

    final currentTxs = transactions
        .where((t) =>
            !t.isTransfer &&
            !t.date.isBefore(currentStart) &&
            t.date.isBefore(currentEnd))
        .toList();

    final previousTxs = transactions
        .where((t) =>
            !t.isTransfer &&
            !t.date.isBefore(previousStart) &&
            t.date.isBefore(previousEnd))
        .toList();

    double currentIncome = 0, currentExpense = 0;
    final Map<String, double> currentByCategory = {};
    for (final tx in currentTxs) {
      if (tx.isIncome) {
        currentIncome += tx.amount;
      } else {
        currentExpense += tx.amount;
        currentByCategory[tx.category] =
            (currentByCategory[tx.category] ?? 0) + tx.amount;
      }
    }

    double previousIncome = 0, previousExpense = 0;
    final Map<String, double> previousByCategory = {};
    for (final tx in previousTxs) {
      if (tx.isIncome) {
        previousIncome += tx.amount;
      } else {
        previousExpense += tx.amount;
        previousByCategory[tx.category] =
            (previousByCategory[tx.category] ?? 0) + tx.amount;
      }
    }

    final deltas = <CategoryDelta>[];

    // Categories present in both months — percentage is well-defined.
    for (final entry in currentByCategory.entries) {
      final prev = previousByCategory[entry.key] ?? 0;
      if (prev == 0) continue; // new category: exclude from ranked deltas
      final deltaPercent = (entry.value - prev) / prev * 100;
      deltas.add(CategoryDelta(
        categoryName: entry.key,
        currentAmount: entry.value,
        previousAmount: prev,
        deltaPercent: deltaPercent,
      ));
    }

    // Categories eliminated this month — treated as -100 %.
    for (final entry in previousByCategory.entries) {
      if (!currentByCategory.containsKey(entry.key)) {
        deltas.add(CategoryDelta(
          categoryName: entry.key,
          currentAmount: 0,
          previousAmount: entry.value,
          deltaPercent: -100,
        ));
      }
    }

    deltas.sort((a, b) => b.deltaPercent.compareTo(a.deltaPercent));
    final topRising =
        deltas.where((d) => d.deltaPercent > 0).take(2).toList();
    final topFalling =
        deltas.reversed.where((d) => d.deltaPercent < 0).take(2).toList();

    return MonthlyComparisonEntity(
      hasPreviousMonthData: previousTxs.isNotEmpty,
      currentIncome: currentIncome,
      currentExpense: currentExpense,
      currentNetFlow: currentIncome - currentExpense,
      previousIncome: previousIncome,
      previousExpense: previousExpense,
      previousNetFlow: previousIncome - previousExpense,
      incomeDelta: currentIncome - previousIncome,
      expenseDelta: currentExpense - previousExpense,
      netFlowDelta: (currentIncome - currentExpense) -
          (previousIncome - previousExpense),
      topRising: topRising,
      topFalling: topFalling,
    );
  }

  static MonthProjectionEntity buildProjection({
    required List<TransactionEntity> transactions,
    required List<BudgetEntity> budgets,
    required DateTime month,
  }) {
    final now = DateTime.now();
    final isCurrentMonth =
        month.year == now.year && month.month == now.month;
    // daysElapsed >= 1 always (day starts at 1, past months use full month).
    final daysElapsed =
        isCurrentMonth ? now.day : _daysInMonth(month.year, month.month);
    final totalDays = _daysInMonth(month.year, month.month);
    final factor = totalDays / daysElapsed;

    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);

    double currentIncome = 0, currentExpense = 0;
    final Map<String, double> expenseByCategory = {};

    for (final tx in transactions) {
      if (tx.isTransfer) continue;
      if (tx.date.isBefore(monthStart) || !tx.date.isBefore(monthEnd)) {
        continue;
      }
      if (tx.isIncome) {
        currentIncome += tx.amount;
      } else {
        currentExpense += tx.amount;
        expenseByCategory[tx.categoryId] =
            (expenseByCategory[tx.categoryId] ?? 0) + tx.amount;
      }
    }

    final ProjectionReliability reliability;
    if (daysElapsed < 7) {
      reliability = ProjectionReliability.low;
    } else if (daysElapsed < 20) {
      reliability = ProjectionReliability.medium;
    } else {
      reliability = ProjectionReliability.high;
    }

    final budgetsAtRisk = <BudgetRisk>[];
    for (final budget in budgets) {
      final categorySpend = expenseByCategory[budget.categoryId] ?? 0;
      final projectedSpend = categorySpend * factor;
      if (projectedSpend > budget.amountLimit) {
        budgetsAtRisk.add(BudgetRisk(
          categoryName: budget.categoryName,
          amountLimit: budget.amountLimit,
          projectedSpend: projectedSpend,
          overagePercent:
              (projectedSpend - budget.amountLimit) / budget.amountLimit * 100,
        ));
      }
    }
    budgetsAtRisk.sort((a, b) => b.overagePercent.compareTo(a.overagePercent));

    return MonthProjectionEntity(
      currentExpense: currentExpense,
      projectedExpense: currentExpense * factor,
      currentIncome: currentIncome,
      projectedIncome: currentIncome * factor,
      projectedNetFlow: (currentIncome - currentExpense) * factor,
      daysElapsed: daysElapsed,
      totalDays: totalDays,
      reliability: reliability,
      budgetsAtRisk: budgetsAtRisk,
    );
  }

  static List<AnalyticsInsightEntity> buildInsights({
    required MonthlyComparisonEntity comparison,
    required List<TransactionEntity> transactions,
    required DateTime month,
  }) {
    final insights = <AnalyticsInsightEntity>[];

    if (comparison.hasPreviousMonthData) {
      for (final delta in comparison.topRising) {
        if (delta.deltaPercent > 20) {
          insights.add(AnalyticsInsightEntity(
            message:
                'Tu gasto en ${delta.categoryName} subió un '
                '${delta.deltaPercent.toStringAsFixed(0)}% respecto al mes pasado',
            severity: InsightSeverity.warning,
          ));
        }
      }

      for (final delta in comparison.topFalling) {
        if (delta.deltaPercent < -20) {
          insights.add(AnalyticsInsightEntity(
            message:
                'Tu gasto en ${delta.categoryName} bajó un '
                '${delta.deltaPercent.abs().toStringAsFixed(0)}% respecto al mes pasado',
            severity: InsightSeverity.positive,
          ));
        }
      }

      if (comparison.netFlowDelta > 0) {
        insights.add(const AnalyticsInsightEntity(
          message: 'Tu ahorro este mes mejoró respecto al mes pasado',
          severity: InsightSeverity.positive,
        ));
      } else if (comparison.netFlowDelta < 0) {
        insights.add(const AnalyticsInsightEntity(
          message: 'Tu ahorro este mes es menor que el mes pasado',
          severity: InsightSeverity.warning,
        ));
      }

      if (comparison.previousIncome > 0) {
        final variance =
            comparison.incomeDelta.abs() / comparison.previousIncome;
        if (variance > 0.30) {
          insights.add(const AnalyticsInsightEntity(
            message: 'Tus ingresos variaron más de lo habitual este mes',
            severity: InsightSeverity.warning,
          ));
        }
      }
    }

    // Account with most outflow — does not require previous month data.
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);
    final Map<String, ({String name, double total})> byAccount = {};
    for (final tx in transactions) {
      if (tx.isTransfer || tx.isIncome) continue;
      if (tx.date.isBefore(monthStart) || !tx.date.isBefore(monthEnd)) {
        continue;
      }
      final existing = byAccount[tx.accountId];
      byAccount[tx.accountId] = (
        name: tx.accountName,
        total: (existing?.total ?? 0) + tx.amount,
      );
    }
    if (byAccount.length > 1) {
      final top = byAccount.entries
          .reduce((a, b) => a.value.total > b.value.total ? a : b);
      insights.add(AnalyticsInsightEntity(
        message:
            'Tu cuenta ${top.value.name} tuvo la mayor salida de dinero este mes',
        severity: InsightSeverity.neutral,
      ));
    }

    return insights.take(5).toList();
  }

  static SavingsRateEntity buildSavingsRate({
    required List<TransactionEntity> transactions,
    required DateTime month,
  }) {
    final currentStart = DateTime(month.year, month.month, 1);
    final currentEnd = DateTime(month.year, month.month + 1, 1);
    final previousStart = DateTime(month.year, month.month - 1, 1);

    double currentIncome = 0, currentExpense = 0;
    double previousIncome = 0, previousExpense = 0;
    bool hasPreviousTxs = false;

    for (final tx in transactions) {
      if (tx.isTransfer) continue;
      if (!tx.date.isBefore(currentStart) && tx.date.isBefore(currentEnd)) {
        if (tx.isIncome) {
          currentIncome += tx.amount;
        } else {
          currentExpense += tx.amount;
        }
      } else if (!tx.date.isBefore(previousStart) &&
          tx.date.isBefore(currentStart)) {
        hasPreviousTxs = true;
        if (tx.isIncome) {
          previousIncome += tx.amount;
        } else {
          previousExpense += tx.amount;
        }
      }
    }

    final savedAmount = currentIncome - currentExpense;
    final rate =
        currentIncome > 0 ? (savedAmount / currentIncome * 100) : 0.0;

    double? previousRate;
    if (hasPreviousTxs && previousIncome > 0) {
      previousRate =
          (previousIncome - previousExpense) / previousIncome * 100;
    }

    return SavingsRateEntity(
      rate: rate,
      income: currentIncome,
      expense: currentExpense,
      savedAmount: savedAmount,
      previousRate: previousRate,
    );
  }

  static CashFlowEntity buildCashFlow({
    required List<TransactionEntity> transactions,
    required DateTime month,
  }) {
    final now = DateTime.now();
    final isCurrentMonth =
        month.year == now.year && month.month == now.month;
    final daysInPeriod =
        isCurrentMonth ? now.day : _daysInMonth(month.year, month.month);

    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);

    final incomeTxs = <TransactionEntity>[];
    final expenseTxs = <TransactionEntity>[];

    for (final tx in transactions) {
      if (tx.isTransfer) continue;
      if (tx.date.isBefore(monthStart) || !tx.date.isBefore(monthEnd)) {
        continue;
      }
      if (tx.isIncome) {
        incomeTxs.add(tx);
      } else {
        expenseTxs.add(tx);
      }
    }

    CashFlowSummary summarise(List<TransactionEntity> txs, int days) {
      final total = txs.fold(0.0, (s, t) => s + t.amount);
      return CashFlowSummary(
        count: txs.length,
        total: total,
        dailyAverage: days > 0 ? total / days : 0,
        perTransactionAverage: txs.isNotEmpty ? total / txs.length : 0,
      );
    }

    return CashFlowEntity(
      income: summarise(incomeTxs, daysInPeriod),
      expense: summarise(expenseTxs, daysInPeriod),
      daysInPeriod: daysInPeriod,
    );
  }

  static LedgerEntity buildLedger({
    required List<TransactionEntity> transactions,
    required LedgerPeriod period,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final DateTime start = switch (period) {
      LedgerPeriod.days7 => today.subtract(const Duration(days: 6)),
      LedgerPeriod.days30 => today.subtract(const Duration(days: 29)),
      LedgerPeriod.thisMonth => DateTime(now.year, now.month, 1),
    };

    final incomeByCategory = <String, ({double amount, int count})>{};
    final expenseByCategory = <String, ({double amount, int count})>{};

    for (final tx in transactions) {
      if (tx.isTransfer) continue;
      if (tx.date.isBefore(start) || tx.date.isAfter(endOfToday)) continue;

      final map = tx.isIncome ? incomeByCategory : expenseByCategory;
      final existing = map[tx.category];
      map[tx.category] = (
        amount: (existing?.amount ?? 0) + tx.amount,
        count: (existing?.count ?? 0) + 1,
      );
    }

    List<LedgerCategoryRow> toRows(
        Map<String, ({double amount, int count})> map) {
      final rows = map.entries
          .map((e) => LedgerCategoryRow(
                categoryName: e.key,
                amount: e.value.amount,
                count: e.value.count,
              ))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
      return rows;
    }

    final incomeRows = toRows(incomeByCategory);
    final expenseRows = toRows(expenseByCategory);

    return LedgerEntity(
      period: period,
      totalIncome: incomeRows.fold(0.0, (s, r) => s + r.amount),
      totalExpense: expenseRows.fold(0.0, (s, r) => s + r.amount),
      incomeRows: incomeRows,
      expenseRows: expenseRows,
    );
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
}
