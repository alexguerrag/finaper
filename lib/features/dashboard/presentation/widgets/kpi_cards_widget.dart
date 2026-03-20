import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class KpiCardsWidget extends StatefulWidget {
  const KpiCardsWidget({super.key});

  @override
  State<KpiCardsWidget> createState() => _KpiCardsWidgetState();
}

class _KpiCardsWidgetState extends State<KpiCardsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _incomeAnim;
  late Animation<double> _expenseAnim;

  static const double _totalIncome = 4820.00;
  static const double _totalExpense = 1972.50;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _incomeAnim = Tween<double>(begin: 0, end: _totalIncome).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _expenseAnim = Tween<double>(begin: 0, end: _totalExpense).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Row(
        children: [
          Expanded(
            child: _KpiCard(
              label: 'Ingresos',
              value: _incomeAnim.value,
              icon: Icons.arrow_downward_rounded,
              color: AppTheme.income,
              change: '+8.2%',
              isPositive: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KpiCard(
              label: 'Gastos',
              value: _expenseAnim.value,
              icon: Icons.arrow_upward_rounded,
              color: AppTheme.expense,
              change: '+3.7%',
              isPositive: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final String change;
  final bool isPositive;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.20), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppTheme.income : AppTheme.expense)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      change,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? AppTheme.income : AppTheme.expense,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '\$${value.toStringAsFixed(0)}',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
