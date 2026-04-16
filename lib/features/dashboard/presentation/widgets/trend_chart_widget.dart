import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/local/dashboard_local_datasource.dart';

class TrendChartWidget extends StatefulWidget {
  const TrendChartWidget({
    super.key,
    required this.data,
  });

  /// Ordered oldest → newest, up to 6 points.
  final List<MonthlyTrendPoint> data;

  @override
  State<TrendChartWidget> createState() => _TrendChartWidgetState();
}

class _TrendChartWidgetState extends State<TrendChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

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
  void didUpdateWidget(TrendChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasData => widget.data.any((p) => p.income > 0 || p.expense > 0);

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
                  const Row(
                    children: [
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
                child: _hasData
                    ? AnimatedBuilder(
                        animation: _anim,
                        builder: (context, child) => LineChart(
                          _buildChartData(_anim.value),
                          duration: Duration.zero,
                        ),
                      )
                    : Center(
                        child: Text(
                          'Sin movimientos en los últimos 6 meses',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          textAlign: TextAlign.center,
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
    final data = widget.data;
    final allValues = data.expand((p) => [p.income, p.expense]);
    final maxVal = allValues.fold<double>(0, (m, v) => v > m ? v : m);
    final chartMax = maxVal <= 0 ? 1000.0 : (maxVal * 1.25).ceilToDouble();
    final interval = (chartMax / 3).ceilToDouble();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
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
            reservedSize: 44,
            interval: interval,
            getTitlesWidget: (val, __) => Text(
              _formatAxisValue(val),
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
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (val, __) {
              final i = val.toInt();
              if (i < 0 || i >= data.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  data[i].label,
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
      maxX: (data.length - 1).toDouble(),
      minY: 0,
      maxY: chartMax,
      lineBarsData: [
        _buildLine(
          spots: List.generate(
            data.length,
            (i) => FlSpot(i.toDouble(), data[i].income * animValue),
          ),
          color: AppTheme.income,
          lastIndex: data.length - 1,
        ),
        _buildLine(
          spots: List.generate(
            data.length,
            (i) => FlSpot(i.toDouble(), data[i].expense * animValue),
          ),
          color: AppTheme.expense,
          lastIndex: data.length - 1,
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots.map((s) {
            final isIncome = s.barIndex == 0;
            return LineTooltipItem(
              _formatTooltipValue(s.y),
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

  LineChartBarData _buildLine({
    required List<FlSpot> spots,
    required Color color,
    required int lastIndex,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, __, index) => FlDotCirclePainter(
          radius: index == lastIndex ? 4 : 0,
          color: color,
          strokeWidth: 2,
          strokeColor: AppTheme.background,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  /// Format axis numbers: ≥1000 → '1k', '2.5k'; <1000 → as-is.
  String _formatAxisValue(double val) {
    if (val >= 1000) {
      final k = val / 1000;
      return k == k.truncateToDouble()
          ? '${k.toInt()}k'
          : '${k.toStringAsFixed(1)}k';
    }
    return val.toInt().toString();
  }

  String _formatTooltipValue(double val) {
    if (val >= 1000) {
      final k = val / 1000;
      return k == k.truncateToDouble()
          ? '\$${k.toInt()}k'
          : '\$${k.toStringAsFixed(1)}k';
    }
    return '\$${val.toStringAsFixed(0)}';
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
