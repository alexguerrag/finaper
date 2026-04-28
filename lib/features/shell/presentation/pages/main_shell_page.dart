import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../accounts/presentation/screens/accounts_screen.dart' show AccountsScreen, AccountsScreenState;
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../transactions/presentation/screens/transactions_screen.dart';
import 'more_screen.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();

  final GlobalKey<AccountsScreenState> _accountsKey =
      GlobalKey<AccountsScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(
        key: _dashboardKey,
        onOpenTransactionsTab: () => _switchTab(1),
        onOpenAccountsTab: () => _switchTab(2),
      ),
      const TransactionsScreen(),
      AccountsScreen(key: _accountsKey),
      MoreScreen(onRefreshDashboard: _refreshDashboard),
    ];
  }

  Future<void> _refreshDashboard() async {
    if (!mounted) return;
    await _dashboardKey.currentState?.refreshSummary();
  }

  Future<void> _switchTab(int index) async {
    if (_currentIndex == index) {
      if (index == 0) await _refreshDashboard();
      return;
    }

    setState(() => _currentIndex = index);

    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDashboard());
    } else if (index == 2) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _accountsKey.currentState?.refresh(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _switchTab,
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.16),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Inicio',
            tooltip: 'Resumen financiero',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Movimientos',
            tooltip: 'Transacciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Cuentas',
            tooltip: 'Mis cuentas',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Más',
            tooltip: 'Más opciones',
          ),
        ],
      ),
    );
  }
}
