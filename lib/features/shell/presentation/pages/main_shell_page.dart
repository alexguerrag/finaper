import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../budgets/presentation/screens/budgets_screen.dart';
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
      DashboardScreen(
        key: _dashboardKey,
        onOpenTransactionsTab: () => _switchTab(1),
        onOpenBudgetsTab: () => _switchTab(2),
      ),
      const TransactionsScreen(),
      const BudgetsScreen(),
    ];
  }

  Future<void> _switchTab(int index) async {
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

  Future<void> _onDestinationSelected(int index) async {
    if (index == 3) {
      _openMoreSheet();
      return;
    }
    await _switchTab(index);
  }

  void _openMoreSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoreSheet(
        onGoals: () async {
          Navigator.pop(context);
          await Navigator.pushNamed(context, AppRoutes.goals);
          if (mounted && _currentIndex == 0) {
            await _dashboardKey.currentState?.refreshSummary();
          }
        },
        onCatalogs: () async {
          Navigator.pop(context);
          await Navigator.pushNamed(context, AppRoutes.catalogs);
          if (mounted && _currentIndex == 0) {
            await _dashboardKey.currentState?.refreshSummary();
          }
        },
        onRecurring: () async {
          Navigator.pop(context);
          await Navigator.pushNamed(context, AppRoutes.recurringTransactions);
          if (mounted && _currentIndex == 0) {
            await _dashboardKey.currentState?.refreshSummary();
          }
        },
        onSettings: () async {
          Navigator.pop(context);
          await Navigator.pushNamed(context, AppRoutes.settings);
          if (mounted) {
            await _dashboardKey.currentState?.refreshSummary();
          }
        },
      ),
    );
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
        onDestinationSelected: _onDestinationSelected,
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
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings_rounded),
            label: 'Presupuestos',
            tooltip: 'Presupuestos del mes',
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

class _MoreSheet extends StatelessWidget {
  const _MoreSheet({
    required this.onGoals,
    required this.onCatalogs,
    required this.onRecurring,
    required this.onSettings,
  });

  final VoidCallback onGoals;
  final VoidCallback onCatalogs;
  final VoidCallback onRecurring;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Más opciones',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _MoreTile(
              icon: Icons.flag_rounded,
              label: 'Metas',
              onTap: onGoals,
            ),
            _MoreTile(
              icon: Icons.folder_outlined,
              label: 'Catálogos',
              onTap: onCatalogs,
            ),
            _MoreTile(
              icon: Icons.repeat_rounded,
              label: 'Recurrentes',
              onTap: onRecurring,
            ),
            _MoreTile(
              icon: Icons.settings_outlined,
              label: 'Ajustes',
              onTap: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.onSurface, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.onSurfaceMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
