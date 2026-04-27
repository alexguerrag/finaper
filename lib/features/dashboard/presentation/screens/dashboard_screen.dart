import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/di/settings_registry.dart';
import '../../data/local/dashboard_local_datasource.dart';
import '../../di/dashboard_registry.dart';
import '../widgets/budget_alert_banner_widget.dart';
import '../widgets/dashboard_budget_summary_widget.dart';
import '../widgets/dashboard_financial_snapshot_widget.dart';
import '../widgets/dashboard_top_expense_categories_widget.dart';
import '../widgets/goal_alert_banner_widget.dart';
import '../widgets/recent_transactions_widget.dart';
import '../widgets/recurring_alert_banner_widget.dart';
import '../widgets/trend_chart_widget.dart';

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
  late DateTime _selectedMonth;

  bool _isLoading = true;
  int _refreshVersion = 0;
  DashboardSummaryData? _summary;

  @override
  void initState() {
    super.initState();
    _dashboardLocalDataSource =
        DashboardRegistry.module.dashboardLocalDataSource;
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
      final localeCode = SettingsRegistry.module.controller.resolvedLocaleCode;
      final summary = await _dashboardLocalDataSource.getSummary(
        month: _selectedMonth,
        localeCode: localeCode,
      );

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('Error loading dashboard summary: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
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
    if (!_canGoToNextMonth) {
      return;
    }

    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      _isLoading = true;
      _refreshVersion++;
    });

    await _loadSummary();
  }

  bool get _canGoToNextMonth {
    final currentMonth = _monthStart(DateTime.now());
    return _selectedMonth.isBefore(currentMonth);
  }

  Future<void> _goToTransactions() async {
    if (widget.onOpenTransactionsTab != null) {
      await widget.onOpenTransactionsTab!.call();
      return;
    }

    await Navigator.pushNamed(context, AppRoutes.transactions);
    if (!mounted) return;
    await refreshSummary();
  }

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

  DateTime _monthStart(DateTime value) {
    return DateTime(value.year, value.month, 1);
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
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : (summary != null && !summary.hasAccounts)
              ? _NoAccountsState(onCreateAccount: widget.onOpenAccountsTab)
              : RefreshIndicator(
              onRefresh: refreshSummary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DashboardFinancialSnapshotWidget(
                    monthLabel: summary?.monthLabel ?? '',
                    consolidatedBalance: summary?.consolidatedBalance ?? 0,
                    netFlow: summary?.monthNetFlow ?? 0,
                    income: summary?.monthIncome ?? 0,
                    expense: summary?.monthExpense ?? 0,
                    canGoToNextMonth: _canGoToNextMonth,
                    onPreviousMonth: _goToPreviousMonth,
                    onNextMonth: _goToNextMonth,
                  ),
                  const SizedBox(height: 16),
                  DashboardBudgetSummaryWidget(
                    month: _selectedMonth,
                    refreshToken: _refreshVersion,
                    onManagePressed: _goToBudgets,
                  ),
                  const SizedBox(height: 16),
                  BudgetAlertBannerWidget(
                    month: _selectedMonth,
                    refreshToken: _refreshVersion,
                    onManagePressed: _goToBudgets,
                  ),
                  const SizedBox(height: 16),
                  RecurringAlertBannerWidget(
                    refreshToken: _refreshVersion,
                    onManagePressed: _goToRecurring,
                  ),
                  const SizedBox(height: 16),
                  GoalAlertBannerWidget(
                    refreshToken: _refreshVersion,
                    onManagePressed: _goToGoals,
                  ),
                  const SizedBox(height: 16),
                  DashboardTopExpenseCategoriesWidget(
                    categories: summary?.topExpenseCategories ?? const [],
                    totalExpense: summary?.monthExpense ?? 0,
                  ),
                  const SizedBox(height: 16),
                  TrendChartWidget(
                    data: summary?.monthlyTrend ?? const [],
                  ),
                  const SizedBox(height: 16),
                  RecentTransactionsWidget(
                    transactionsOverride: summary?.recentTransactions,
                    onSeeAll: _goToTransactions,
                  ),
                ],
              ),
            ),
    );
  }
}

class _NoAccountsState extends StatelessWidget {
  const _NoAccountsState({this.onCreateAccount});

  final Future<void> Function()? onCreateAccount;

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
              'Primero crea una cuenta',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Las cuentas representan dónde tienes tu dinero:\nbanco, efectivo o tarjeta.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 20),
            const Wrap(
              spacing: 8,
              children: [
                _ExampleChip(label: 'Banco'),
                _ExampleChip(label: 'Efectivo'),
                _ExampleChip(label: 'Tarjeta'),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreateAccount,
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Crear cuenta',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurfaceMuted,
        ),
      ),
    );
  }
}
