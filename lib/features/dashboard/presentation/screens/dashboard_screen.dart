import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/database_helper.dart';
import '../../../transactions/data/local/transaction_local_datasource.dart';
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
  late final DashboardLocalDataSource _dashboardLocalDataSource;

  bool _isLoading = true;
  DashboardSummaryData? _summary;

  @override
  void initState() {
    super.initState();
    _dashboardLocalDataSource = DashboardLocalDataSource(
      TransactionLocalDataSourceImpl(DatabaseHelper.instance),
    );
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _dashboardLocalDataSource.getSummary();

      if (!mounted) return;

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard summary: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _goToTransactions() async {
    await Navigator.pushNamed(context, AppRoutes.transactions);
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    // ... resto del código del build (se mantiene igual)
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Finaper',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
            Text('Hola, Sofía 👋',
                style: GoogleFonts.manrope(
                    fontSize: 12, color: AppTheme.onSurfaceMuted)),
          ],
        ),
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
                BalanceHeroWidget(balanceOverride: _summary?.balance),
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
