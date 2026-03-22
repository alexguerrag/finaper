import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../transactions/presentation/screens/transactions_screen.dart';
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
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardLocalDataSource _dashboardLocalDataSource =
      DashboardLocalDataSource();

  bool _isLoading = true;
  DashboardSummaryData? _summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final summary = await _dashboardLocalDataSource.getSummary();

    if (!mounted) return;

    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  Future<void> _goToTransactions() async {
    await Navigator.pushNamed(context, AppRoutes.transactions);

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    await _loadSummary();
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
                color: AppTheme.onSurface,
              ),
            ),
            Text(
              'Hola, Sofía 👋',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _goToTransactions,
            icon: const Icon(Icons.receipt_long_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const BudgetAlertBannerWidget(),
                const SizedBox(height: 12),
                BalanceHeroWidget(
                  balanceOverride: _summary?.balance,
                ),
                const SizedBox(height: 12),
                KpiCardsWidget(
                  incomeOverride: _summary?.totalIncome,
                  expenseOverride: _summary?.totalExpense,
                ),
                const SizedBox(height: 16),
                const TrendChartWidget(),
                const SizedBox(height: 16),
                const BudgetBarsWidget(),
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
