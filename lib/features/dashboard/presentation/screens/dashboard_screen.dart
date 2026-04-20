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
import '../widgets/recent_transactions_widget.dart';
import '../widgets/trend_chart_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.onOpenTransactionsTab,
    this.onOpenBudgetsTab,
  });

  final Future<void> Function()? onOpenTransactionsTab;
  final Future<void> Function()? onOpenBudgetsTab;

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
              ),
            ),
            Text(
              'Tu inicio financiero',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.onSurfaceMuted,
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
