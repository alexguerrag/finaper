import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/di/app_services.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/local/dashboard_local_datasource.dart';
import '../widgets/balance_hero_widget.dart';
import '../widgets/budget_alert_banner_widget.dart';
import '../widgets/budget_bars_widget.dart';
import '../widgets/kpi_cards_widget.dart';
import '../widgets/recent_transactions_widget.dart';
import '../widgets/trend_chart_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  late final DashboardLocalDataSource _dashboardLocalDataSource;

  bool _isLoading = true;
  int _refreshVersion = 0;
  DashboardSummaryData? _summary;

  @override
  void initState() {
    super.initState();
    _dashboardLocalDataSource = AppServices.instance.dashboardLocalDataSource;
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
      final summary = await _dashboardLocalDataSource.getSummary();

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

  Future<void> _goToTransactions() async {
    await Navigator.pushNamed(context, AppRoutes.transactions);
    if (!mounted) return;
    await refreshSummary();
  }

  Future<void> _goToCatalogs() async {
    await Navigator.pushNamed(context, AppRoutes.catalogs);
    if (!mounted) return;
    await refreshSummary();
  }

  Future<void> _goToBudgets() async {
    await Navigator.pushNamed(context, AppRoutes.budgets);
    if (!mounted) return;
    await refreshSummary();
  }

  Future<void> _goToGoals() async {
    await Navigator.pushNamed(context, AppRoutes.goals);
    if (!mounted) return;
    await refreshSummary();
  }

  Future<void> _goToRecurringTransactions() async {
    await Navigator.pushNamed(context, AppRoutes.recurringTransactions);
    if (!mounted) return;
    await refreshSummary();
  }

  @override
  Widget build(BuildContext context) {
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
              'Tu resumen financiero',
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
          IconButton(
            onPressed: _goToBudgets,
            icon: const Icon(Icons.savings_rounded),
            tooltip: 'Presupuestos',
          ),
          PopupMenuButton<_DashboardMenuAction>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case _DashboardMenuAction.catalogs:
                  _goToCatalogs();
                  break;
                case _DashboardMenuAction.transactions:
                  _goToTransactions();
                  break;
                case _DashboardMenuAction.recurring:
                  _goToRecurringTransactions();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _DashboardMenuAction.catalogs,
                child: Text('Catálogos'),
              ),
              PopupMenuItem(
                value: _DashboardMenuAction.transactions,
                child: Text('Movimientos'),
              ),
              PopupMenuItem(
                value: _DashboardMenuAction.recurring,
                child: Text('Recurrentes'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                BudgetAlertBannerWidget(
                  refreshToken: _refreshVersion,
                  onManagePressed: _goToBudgets,
                ),
                const SizedBox(height: 12),
                BalanceHeroWidget(balanceOverride: _summary?.balance),
                const SizedBox(height: 12),
                KpiCardsWidget(
                  incomeOverride: _summary?.totalIncome,
                  expenseOverride: _summary?.totalExpense,
                ),
                const SizedBox(height: 16),
                const TrendChartWidget(),
                const SizedBox(height: 16),
                BudgetBarsWidget(
                  refreshToken: _refreshVersion,
                  onManagePressed: _goToBudgets,
                ),
                const SizedBox(height: 16),
                RecentTransactionsWidget(
                  transactionsOverride: _summary?.recentTransactions,
                  onSeeAll: _goToTransactions,
                ),
              ],
            ),
    );
  }
}

enum _DashboardMenuAction {
  catalogs,
  transactions,
  recurring,
}
