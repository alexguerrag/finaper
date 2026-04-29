import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../analytics/di/analytics_registry.dart';
import '../../../analytics/domain/entities/analytics_insight_entity.dart';
import '../../../analytics/domain/entities/month_projection_entity.dart';
import '../../../analytics/domain/entities/monthly_comparison_entity.dart';
import '../../../analytics/domain/entities/premium_reports_entity.dart';
import '../../../analytics/domain/usecases/get_premium_reports.dart';
import '../../../settings/di/settings_registry.dart';
import '../../data/local/dashboard_local_datasource.dart';
import '../../di/dashboard_registry.dart';
import '../../domain/entities/dashboard_card_type.dart';
import '../../domain/entities/dashboard_config.dart';
import '../widgets/budget_alert_banner_widget.dart';
import '../widgets/dashboard_budget_summary_widget.dart';
import '../widgets/dashboard_financial_snapshot_widget.dart';
import '../widgets/dashboard_top_expense_categories_widget.dart';
import '../widgets/goal_alert_banner_widget.dart';
import '../widgets/recurring_alert_banner_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.onOpenTransactionsTab,
    this.onOpenBudgetsTab,
    this.onOpenAccountsTab,
  });

  final Future<void> Function()? onOpenTransactionsTab;
  final Future<void> Function()? onOpenBudgetsTab;
  final Future<void> Function()? onOpenAccountsTab;

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  late final DashboardLocalDataSource _dashboardLocalDataSource;
  late final GetPremiumReports _getPremiumReports;
  late final bool _hasPremiumAccess;
  late DateTime _selectedMonth;

  bool _isLoading = true;
  int _refreshVersion = 0;
  DashboardSummaryData? _summary;
  PremiumReportsEntity? _reports;

  @override
  void initState() {
    super.initState();
    _dashboardLocalDataSource =
        DashboardRegistry.module.dashboardLocalDataSource;
    _getPremiumReports = AnalyticsRegistry.module.getPremiumReports;
    _hasPremiumAccess =
        AnalyticsRegistry.module.entitlementService.hasPremiumAccess;
    _selectedMonth = _monthStart(DateTime.now());
    _loadSummary();
  }

  Future<void> refreshSummary() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _refreshVersion++;
    });
    await _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final localeCode =
          SettingsRegistry.module.controller.resolvedLocaleCode;
      final summary = await _dashboardLocalDataSource.getSummary(
        month: _selectedMonth,
        localeCode: localeCode,
      );

      PremiumReportsEntity? reports;
      if (_hasPremiumAccess) {
        try {
          reports = await _getPremiumReports(month: _selectedMonth);
        } catch (_) {
          // Analytics failure is non-fatal — Free cards still render.
        }
      }

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _reports = reports;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('Error loading dashboard summary: $e');
      debugPrintStack(stackTrace: s);
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _goToPreviousMonth() async {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
      _isLoading = true;
      _refreshVersion++;
    });
    await _loadSummary();
  }

  Future<void> _goToNextMonth() async {
    if (!_canGoToNextMonth) return;
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      _isLoading = true;
      _refreshVersion++;
    });
    await _loadSummary();
  }

  bool get _canGoToNextMonth =>
      _selectedMonth.isBefore(_monthStart(DateTime.now()));

  Future<void> _goToBudgets() async {
    if (widget.onOpenBudgetsTab != null) {
      await widget.onOpenBudgetsTab!.call();
      return;
    }
    await Navigator.pushNamed(context, AppRoutes.budgets);
    if (!mounted) return;
    await refreshSummary();
  }

  Future<void> _goToGoals() async {
    await Navigator.pushNamed(context, AppRoutes.goals);
    if (!mounted) return;
    await refreshSummary();
  }

  Future<void> _goToRecurring() async {
    await Navigator.pushNamed(context, AppRoutes.recurringTransactions);
    if (!mounted) return;
    await refreshSummary();
  }

  DateTime _monthStart(DateTime value) => DateTime(value.year, value.month, 1);

  void _showUpgradeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _UpgradeSheet(),
    );
  }

  Widget _buildCard(
    BuildContext context,
    DashboardCardType type,
    DashboardSummaryData summary,
  ) {
    if (type.isPremium && !_hasPremiumAccess) {
      return _LockedCard(
        type: type,
        onTap: () => _showUpgradeSheet(context),
      );
    }

    return switch (type) {
      DashboardCardType.monthlyFlow => DashboardFinancialSnapshotWidget(
          monthLabel: summary.monthLabel,
          consolidatedBalance: summary.consolidatedBalance,
          netFlow: summary.monthNetFlow,
          income: summary.monthIncome,
          expense: summary.monthExpense,
          canGoToNextMonth: _canGoToNextMonth,
          onPreviousMonth: _goToPreviousMonth,
          onNextMonth: _goToNextMonth,
          onGoToAccounts: widget.onOpenAccountsTab != null
              ? () => widget.onOpenAccountsTab!()
              : null,
        ),
      DashboardCardType.totalBalance => _TotalBalanceCard(
          balance: summary.consolidatedBalance,
          onGoToAccounts: widget.onOpenAccountsTab,
        ),
      DashboardCardType.budgetSummary => DashboardBudgetSummaryWidget(
          month: _selectedMonth,
          refreshToken: _refreshVersion,
          onManagePressed: _goToBudgets,
        ),
      DashboardCardType.expenseBreakdown => DashboardTopExpenseCategoriesWidget(
          categories: summary.topExpenseCategories,
          totalExpense: summary.monthExpense,
        ),
      DashboardCardType.monthlyComparison => _reports != null
          ? _MonthlyComparisonCard(data: _reports!.comparison)
          : const SizedBox.shrink(),
      DashboardCardType.projection => _reports != null
          ? _ProjectionCard(data: _reports!.projection)
          : const SizedBox.shrink(),
      DashboardCardType.insights => _InsightsCard(
          insights: _reports?.insights ?? const [],
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finaper',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFCDD5E0),
              ),
            ),
            Text(
              'Controla tu dinero',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFFB8A060),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _goToGoals,
            icon: const Icon(Icons.flag_rounded),
            tooltip: 'Metas',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (summary != null && !summary.hasAnyAccounts)
              ? _NoAccountsState(onGoToAccounts: widget.onOpenAccountsTab)
              : (summary != null && !summary.hasAnyTransactions)
                  ? _NoTransactionsState(
                      onGoToTransactions: widget.onOpenTransactionsTab)
                  : RefreshIndicator(
                      onRefresh: refreshSummary,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          BudgetAlertBannerWidget(
                            month: _selectedMonth,
                            refreshToken: _refreshVersion,
                            onManagePressed: _goToBudgets,
                          ),
                          RecurringAlertBannerWidget(
                            refreshToken: _refreshVersion,
                            onManagePressed: _goToRecurring,
                          ),
                          GoalAlertBannerWidget(
                            refreshToken: _refreshVersion,
                            onManagePressed: _goToGoals,
                          ),
                          ...DashboardConfig.defaultConfig.activeCards.map(
                            (type) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildCard(context, type, summary!),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

// ---------------------------------------------------------------------------
// Free cards
// ---------------------------------------------------------------------------

class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({
    required this.balance,
    this.onGoToAccounts,
  });

  final double balance;
  final Future<void> Function()? onGoToAccounts;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onGoToAccounts != null ? () => onGoToAccounts!() : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Saldo total',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
                const Spacer(),
                if (onGoToAccounts != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.onSurfaceMuted,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppFormatters.formatCurrency(balance),
              style: GoogleFonts.manrope(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: -0.8,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium cards
// ---------------------------------------------------------------------------

class _MonthlyComparisonCard extends StatelessWidget {
  const _MonthlyComparisonCard({required this.data});

  final MonthlyComparisonEntity data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows_rounded,
                  size: 14, color: AppTheme.onSurfaceMuted),
              const SizedBox(width: 6),
              Text(
                'COMPARACIÓN MENSUAL',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),
          if (!data.hasPreviousMonthData)
            Text(
              'Aún no hay suficientes datos para comparar con el mes anterior.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.onSurfaceMuted,
                height: 1.4,
              ),
            )
          else ...[
            _ComparisonRow(
              label: 'Ingresos',
              current: data.currentIncome,
              delta: data.incomeDelta,
            ),
            const SizedBox(height: 10),
            _ComparisonRow(
              label: 'Gastos',
              current: data.currentExpense,
              delta: data.expenseDelta,
            ),
            const SizedBox(height: 10),
            _ComparisonRow(
              label: 'Flujo del mes',
              current: data.currentNetFlow,
              delta: data.netFlowDelta,
              bold: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.current,
    required this.delta,
    this.bold = false,
  });

  final String label;
  final double current;
  final double delta;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final deltaColor = isPositive ? AppTheme.income : AppTheme.expense;
    final deltaSign = isPositive ? '+' : '';
    final deltaText =
        '$deltaSign${AppFormatters.formatCurrency(delta.abs())}';

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
            ),
          ),
        ),
        Text(
          AppFormatters.formatCurrency(current.abs()),
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: deltaColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 10,
                color: deltaColor,
              ),
              const SizedBox(width: 2),
              Text(
                deltaText,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: deltaColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.data});

  final MonthProjectionEntity data;

  @override
  Widget build(BuildContext context) {
    final isPositive = data.projectedNetFlow >= 0;
    final flowColor = isPositive ? AppTheme.income : AppTheme.expense;

    final (reliabilityLabel, reliabilityColor) = switch (data.reliability) {
      ProjectionReliability.low => ('Baja confianza', AppTheme.expense),
      ProjectionReliability.medium => ('Confianza media', const Color(0xFFF5A623)),
      ProjectionReliability.high => ('Alta confianza', AppTheme.income),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  size: 14, color: AppTheme.onSurfaceMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'PROYECCIÓN DE CIERRE',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: reliabilityColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: reliabilityColor.withValues(alpha: 0.28)),
                ),
                child: Text(
                  reliabilityLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: reliabilityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),
          _ProjectionRow(
            label: 'Cierre estimado',
            value: _formatSigned(data.projectedNetFlow),
            color: flowColor,
            large: true,
          ),
          const SizedBox(height: 8),
          _ProjectionRow(
            label: 'Ingresos proyectados',
            value: AppFormatters.formatCurrency(data.projectedIncome),
            color: AppTheme.income,
          ),
          const SizedBox(height: 8),
          _ProjectionRow(
            label: 'Gastos proyectados',
            value: AppFormatters.formatCurrency(data.projectedExpense),
            color: AppTheme.expense,
          ),
          if (data.budgetsAtRisk.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),
            Text(
              'Presupuestos en riesgo',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...data.budgetsAtRisk.take(2).map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: Color(0xFFF5A623)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.categoryName,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '+${r.overagePercent.toStringAsFixed(0)}%',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.expense,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _formatSigned(double value) {
    final f = AppFormatters.formatCurrency(value.abs());
    if (value > 0) return '+$f';
    if (value < 0) return '-$f';
    return AppFormatters.formatCurrency(0);
  }
}

class _ProjectionRow extends StatelessWidget {
  const _ProjectionRow({
    required this.label,
    required this.value,
    required this.color,
    this.large = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: large ? 14 : 13,
              fontWeight: large ? FontWeight.w700 : FontWeight.w500,
              color: large ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: large ? 20 : 13,
            fontWeight: large ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.insights});

  final List<AnalyticsInsightEntity> insights;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 14, color: AppTheme.onSurfaceMuted),
              const SizedBox(width: 6),
              Text(
                'INSIGHTS',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),
          if (insights.isEmpty)
            Text(
              'Aún no hay suficientes datos para generar insights.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.onSurfaceMuted,
                height: 1.4,
              ),
            )
          else
            ...insights.take(2).map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: _severityColor(insight.severity),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            insight.message,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: AppTheme.onSurface,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Color _severityColor(InsightSeverity severity) => switch (severity) {
        InsightSeverity.positive => AppTheme.income,
        InsightSeverity.warning => const Color(0xFFF5A623),
        InsightSeverity.neutral => AppTheme.onSurfaceMuted,
      };
}

// ---------------------------------------------------------------------------
// Locked card (Premium gate)
// ---------------------------------------------------------------------------

class _LockedCard extends StatelessWidget {
  const _LockedCard({required this.type, required this.onTap});

  final DashboardCardType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (title, description, icon) = switch (type) {
      DashboardCardType.monthlyComparison => (
          'Comparación mensual',
          '¿Cómo vas vs el mismo punto del mes anterior?',
          Icons.compare_arrows_rounded,
        ),
      DashboardCardType.projection => (
          'Proyección de cierre',
          '¿Terminarás el mes en positivo o negativo?',
          Icons.trending_up_rounded,
        ),
      DashboardCardType.insights => (
          'Insights automáticos',
          'Recomendaciones basadas en tus finanzas.',
          Icons.lightbulb_outline_rounded,
        ),
      _ => ('', '', Icons.lock_outline_rounded),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Icon(icon, color: AppTheme.onSurfaceMuted, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Premium',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.lock_outline_rounded,
                color: AppTheme.onSurfaceMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _UpgradeSheet extends StatelessWidget {
  const _UpgradeSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppTheme.primary, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Disponible en Premium',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Desbloquea proyecciones de cierre, insights automáticos y más para tener mayor control de tus finanzas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.onSurfaceMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Próximamente',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty states
// ---------------------------------------------------------------------------

class _NoAccountsState extends StatelessWidget {
  const _NoAccountsState({this.onGoToAccounts});

  final Future<void> Function()? onGoToAccounts;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Configura tu primera cuenta',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Las cuentas representan dónde tienes tu dinero.\nEj: banco, efectivo o tarjeta.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onGoToAccounts,
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.account_balance_wallet_rounded),
              label: Text(
                'Ir a Cuentas',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoTransactionsState extends StatelessWidget {
  const _NoTransactionsState({this.onGoToTransactions});

  final Future<void> Function()? onGoToTransactions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Registra tu primer movimiento',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Los movimientos son tus ingresos y gastos del día a día.\nEj: sueldo, supermercado, transporte.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onGoToTransactions,
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Agregar movimiento',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
