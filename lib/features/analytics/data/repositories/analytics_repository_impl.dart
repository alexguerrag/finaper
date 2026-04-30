import '../../../budgets/domain/repositories/budgets_repository.dart';
import '../../../transactions/domain/repositories/transactions_repository.dart';
import '../../domain/entities/ledger_entity.dart';
import '../../domain/entities/premium_reports_entity.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../analytics_engine.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  const AnalyticsRepositoryImpl({
    required TransactionsRepository transactionsRepository,
    required BudgetsRepository budgetsRepository,
  })  : _transactionsRepository = transactionsRepository,
        _budgetsRepository = budgetsRepository;

  final TransactionsRepository _transactionsRepository;
  final BudgetsRepository _budgetsRepository;

  @override
  Future<PremiumReportsEntity> getReports({
    required DateTime month,
    required LedgerPeriod ledgerPeriod,
  }) async {
    final monthKey =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';

    final transactions = await _transactionsRepository.getAll();
    final budgets =
        await _budgetsRepository.getBudgetsByMonth(monthKey: monthKey);

    final comparison = AnalyticsEngine.buildComparison(
      transactions: transactions,
      month: month,
    );
    final projection = AnalyticsEngine.buildProjection(
      transactions: transactions,
      budgets: budgets,
      month: month,
    );
    final insights = AnalyticsEngine.buildInsights(
      comparison: comparison,
      transactions: transactions,
      month: month,
    );
    final savingsRate = AnalyticsEngine.buildSavingsRate(
      transactions: transactions,
      month: month,
    );
    final cashFlow = AnalyticsEngine.buildCashFlow(
      transactions: transactions,
      period: ledgerPeriod,
    );
    final ledger = AnalyticsEngine.buildLedger(
      transactions: transactions,
      period: ledgerPeriod,
    );

    return PremiumReportsEntity(
      comparison: comparison,
      projection: projection,
      insights: insights,
      month: month,
      savingsRate: savingsRate,
      cashFlow: cashFlow,
      ledger: ledger,
    );
  }
}
