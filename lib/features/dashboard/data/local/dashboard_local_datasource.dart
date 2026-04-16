import '../../../../core/formatters/app_formatters.dart';
import '../../../accounts/data/local/accounts_local_datasource.dart';
import '../../../transactions/data/local/transaction_local_datasource.dart';
import '../../../transactions/data/models/transaction_model.dart';

class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.monthKey,
    required this.label,
    required this.income,
    required this.expense,
  });

  /// 'YYYY-MM' — used for ordering
  final String monthKey;

  /// Short display label, e.g. 'Ene', 'Feb'
  final String label;

  final double income;
  final double expense;
}

class DashboardExpenseCategorySummary {
  const DashboardExpenseCategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.colorValue,
  });

  final String categoryId;
  final String categoryName;
  final double amount;
  final double percentage;
  final int? colorValue;
}

class DashboardSummaryData {
  const DashboardSummaryData({
    required this.consolidatedBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.recentTransactions,
    required this.monthIncome,
    required this.monthExpense,
    required this.monthNetFlow,
    required this.monthLabel,
    required this.topExpenseCategories,
    required this.hasTransactionsInMonth,
    required this.monthlyTrend,
  });

  final double consolidatedBalance;
  final double totalIncome;
  final double totalExpense;
  final List<TransactionModel> recentTransactions;

  final double monthIncome;
  final double monthExpense;
  final double monthNetFlow;
  final String monthLabel;
  final List<DashboardExpenseCategorySummary> topExpenseCategories;
  final bool hasTransactionsInMonth;
  final List<MonthlyTrendPoint> monthlyTrend;
}

class DashboardLocalDataSource {
  const DashboardLocalDataSource(
    this._transactionLocalDataSource,
    this._accountsLocalDataSource,
  );

  final TransactionLocalDataSource _transactionLocalDataSource;
  final AccountsLocalDataSource _accountsLocalDataSource;

  Future<DashboardSummaryData> getSummary({
    DateTime? month,
    String localeCode = 'es_CL',
  }) async {
    final transactions = await _transactionLocalDataSource.getTransactions();
    final accountBalances = await _accountsLocalDataSource.getAccountBalances();

    final consolidatedBalance = accountBalances.fold<double>(
      0,
      (sum, item) => sum + item.currentBalance,
    );

    double totalIncome = 0;
    double totalExpense = 0;

    for (final transaction in transactions) {
      if (transaction.isTransfer) {
        continue;
      }

      if (transaction.isIncome) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    final sorted = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final selectedMonth = _monthStart(month ?? DateTime.now());
    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    double monthIncome = 0;
    double monthExpense = 0;

    final monthTransactions = <TransactionModel>[];
    final Map<String, _ExpenseCategoryAccumulator> expenseByCategory = {};

    for (final transaction in sorted) {
      final date = transaction.date;
      final isInSelectedMonth =
          !date.isBefore(selectedMonth) && date.isBefore(nextMonth);

      if (!isInSelectedMonth) {
        continue;
      }

      if (transaction.isTransfer) {
        continue;
      }

      monthTransactions.add(transaction);

      if (transaction.isIncome) {
        monthIncome += transaction.amount;
        continue;
      }

      monthExpense += transaction.amount;

      final existing = expenseByCategory[transaction.categoryId];
      if (existing == null) {
        expenseByCategory[transaction.categoryId] = _ExpenseCategoryAccumulator(
          categoryId: transaction.categoryId,
          categoryName: transaction.category,
          amount: transaction.amount,
          colorValue: transaction.color?.toARGB32(),
        );
      } else {
        expenseByCategory[transaction.categoryId] = existing.copyWith(
          amount: existing.amount + transaction.amount,
          colorValue: existing.colorValue ?? transaction.color?.toARGB32(),
        );
      }
    }

    final topExpenseCategories = expenseByCategory.values
        .map(
          (item) => DashboardExpenseCategorySummary(
            categoryId: item.categoryId,
            categoryName: item.categoryName,
            amount: item.amount,
            percentage: monthExpense > 0 ? item.amount / monthExpense : 0,
            colorValue: item.colorValue,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final monthlyTrend = _buildMonthlyTrend(
      transactions: transactions,
      months: 6,
      localeCode: localeCode,
    );

    return DashboardSummaryData(
      consolidatedBalance: consolidatedBalance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      recentTransactions: monthTransactions.take(5).toList(),
      monthIncome: monthIncome,
      monthExpense: monthExpense,
      monthNetFlow: monthIncome - monthExpense,
      monthLabel: AppFormatters.formatMonthYearWith(
        value: selectedMonth,
        localeCode: localeCode,
      ),
      topExpenseCategories: topExpenseCategories.take(4).toList(),
      hasTransactionsInMonth: monthTransactions.isNotEmpty,
      monthlyTrend: monthlyTrend,
    );
  }

  List<MonthlyTrendPoint> _buildMonthlyTrend({
    required List<TransactionModel> transactions,
    required int months,
    required String localeCode,
  }) {
    final now = DateTime.now();
    // Build slots for the last [months] months, oldest first
    final slots = List.generate(months, (i) {
      final d = DateTime(now.year, now.month - (months - 1 - i), 1);
      return DateTime(d.year, d.month, 1);
    });

    final Map<String, ({double income, double expense})> buckets = {
      for (final s in slots) _monthKey(s): (income: 0.0, expense: 0.0),
    };

    for (final tx in transactions) {
      if (tx.isTransfer) continue;
      final key = _monthKey(tx.date);
      if (!buckets.containsKey(key)) continue;
      final current = buckets[key]!;
      if (tx.isIncome) {
        buckets[key] =
            (income: current.income + tx.amount, expense: current.expense);
      } else {
        buckets[key] =
            (income: current.income, expense: current.expense + tx.amount);
      }
    }

    return slots.map((s) {
      final key = _monthKey(s);
      final bucket = buckets[key]!;
      return MonthlyTrendPoint(
        monthKey: key,
        label: _shortMonthLabel(s.month, localeCode),
        income: bucket.income,
        expense: bucket.expense,
      );
    }).toList();
  }

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static const List<String> _shortMonthsEs = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  static const List<String> _shortMonthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _shortMonthsPt = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  String _shortMonthLabel(int month, String localeCode) {
    final lang = localeCode.split('_').first.toLowerCase();
    final list = switch (lang) {
      'en' => _shortMonthsEn,
      'pt' => _shortMonthsPt,
      _ => _shortMonthsEs,
    };
    return list[month - 1];
  }

  DateTime _monthStart(DateTime value) {
    return DateTime(value.year, value.month, 1);
  }
}

class _ExpenseCategoryAccumulator {
  const _ExpenseCategoryAccumulator({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.colorValue,
  });

  final String categoryId;
  final String categoryName;
  final double amount;
  final int? colorValue;

  _ExpenseCategoryAccumulator copyWith({
    double? amount,
    int? colorValue,
  }) {
    return _ExpenseCategoryAccumulator(
      categoryId: categoryId,
      categoryName: categoryName,
      amount: amount ?? this.amount,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
