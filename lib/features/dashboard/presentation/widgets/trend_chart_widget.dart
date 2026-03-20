import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class TrendChartWidget extends StatefulWidget {
  const TrendChartWidget({super.key});

  @override
  State<TrendChartWidget> createState() => _TrendChartWidgetState();
}

class _TrendChartWidgetState extends State<TrendChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  static const List<String> _months = [
    'Oct',
    'Nov',
    'Dic',
    'Ene',
    'Feb',
    'Mar',
  ];
  static const List<double> _income = [4200, 4650, 5100, 4820, 4980, 4820];
  static const List<double> _expenses = [2800, 3100, 3850, 2640, 2210, 1972];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tendencia 6 meses',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        'Ingresos vs Gastos',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppTheme.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      _Legend(color: AppTheme.income, label: 'Ingresos'),
                      SizedBox(width: 12),
                      _Legend(color: AppTheme.expense, label: 'Gastos'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, _) => LineChart(
                    _buildChartData(_anim.value),
                    duration: Duration.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LineChartData _buildChartData(double animValue) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1000,
        getDrawingHorizontalLine: (_) => FlLine(
          color: Colors.white.withValues(alpha: 0.08),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 2000,
            getTitlesWidget: (val, _) => Text(
              '\$${(val / 1000).toStringAsFixed(0)}k',
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (val, _) {
              final i = val.toInt();
              if (i < 0 || i >= _months.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _months[i],
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 5,
      minY: 0,
      maxY: 6000,
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(
            _income.length,
            (i) => FlSpot(i.toDouble(), _income[i] * animValue),
          ),
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppTheme.income,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, _, index) => FlDotCirclePainter(
              radius: index == _income.length - 1 ? 4 : 0,
              color: AppTheme.income,
              strokeWidth: 2,
              strokeColor: AppTheme.background,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.income.withValues(alpha: 0.18),
                AppTheme.income.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        LineChartBarData(
          spots: List.generate(
            _expenses.length,
            (i) => FlSpot(i.toDouble(), _expenses[i] * animValue),
          ),
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppTheme.expense,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, _, index) => FlDotCirclePainter(
              radius: index == _expenses.length - 1 ? 4 : 0,
              color: AppTheme.expense,
              strokeWidth: 2,
              strokeColor: AppTheme.background,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.expense.withValues(alpha: 0.14),
                AppTheme.expense.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          tooltipRoundedRadius: 10,
          tooltipBgColor: AppTheme.surfaceElevated,
          getTooltipItems: (spots) => spots.map((s) {
            final isIncome = s.barIndex == 0;
            return LineTooltipItem(
              '\$${s.y.toStringAsFixed(0)}',
              GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isIncome ? AppTheme.income : AppTheme.expense,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}
