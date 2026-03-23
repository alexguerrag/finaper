import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../transactions/presentation/screens/transactions_screen.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(key: _dashboardKey),
      const TransactionsScreen(),
    ];
  }

  Future<void> _onTap(int index) async {
    if (_currentIndex == index) {
      if (index == 0) {
        await _dashboardKey.currentState?.refreshSummary();
      }
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _dashboardKey.currentState?.refreshSummary();
      });
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
        onDestinationSelected: (index) {
          _onTap(index);
        },
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.16),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
            tooltip: 'Resumen financiero',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Movimientos',
            tooltip: 'Transacciones',
          ),
        ],
      ),
    );
  }
}
