import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/data/local/dashboard_local_datasource.dart';
import '../../../dashboard/di/dashboard_registry.dart';
import '../../../dashboard/presentation/widgets/trend_chart_widget.dart';
import '../../di/analytics_registry.dart';
import '../../domain/entities/analytics_insight_entity.dart';
import '../../domain/entities/month_projection_entity.dart';
import '../../domain/entities/monthly_comparison_entity.dart';
import '../controllers/premium_reports_controller.dart';

class PremiumReportsScreen extends StatefulWidget {
  const PremiumReportsScreen({super.key});

  @override
  State<PremiumReportsScreen> createState() => _PremiumReportsScreenState();
}

class _PremiumReportsScreenState extends State<PremiumReportsScreen> {
  late final PremiumReportsController _controller;
  late final DateTime _month;
  List<MonthlyTrendPoint>? _trend;

  @override
  void initState() {
    super.initState();
    _controller = AnalyticsRegistry.module.controller;
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _controller.load(_month);
    _loadTrend();
  }

  Future<void> _loadTrend() async {
    try {
      final summary = await DashboardRegistry.module.dashboardLocalDataSource
          .getSummary(month: _month);
      if (mounted) setState(() => _trend = summary.monthlyTrend);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Reportes',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.errorMessage != null) {
            return Center(
              child: Text(
                _controller.errorMessage!,
                style: GoogleFonts.manrope(color: AppTheme.onSurfaceMuted),
              ),
            );
          }
          final reports = _controller.reports;
          if (reports == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () => _controller.load(_month),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ComparisonCard(comparison: reports.comparison),
                const SizedBox(height: 16),
                _ProjectionCard(projection: reports.projection),
                const SizedBox(height: 16),
                _InsightsCard(insights: reports.insights),
                if (_trend != null && _trend!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ReportCard(
                    title: 'Tendencia 6 meses',
                    icon: Icons.show_chart_rounded,
                    child: TrendChartWidget(data: _trend!),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Shared primitives ─────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
              height: 1, color: Colors.white.withValues(alpha: 0.06)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _NoDataState extends StatelessWidget {
  const _NoDataState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded,
            size: 16, color: AppTheme.onSurfaceMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppTheme.onSurfaceMuted,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Comparación mensual ───────────────────────────────────────────────────────

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.comparison});

  final MonthlyComparisonEntity comparison;

  @override
  Widget build(BuildContext context) {
    if (!comparison.hasPreviousMonthData) {
      return const _ReportCard(
        title: 'Comparación mensual',
        icon: Icons.compare_arrows_rounded,
        child: _NoDataState(
          message:
              'Aún no hay suficientes datos para comparar con el mes anterior.',
        ),
      );
    }

    return _ReportCard(
      title: 'Comparación mensual',
      icon: Icons.compare_arrows_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DeltaRow(
            label: 'Ingresos',
            delta: comparison.incomeDelta,
            positiveIsGood: true,
          ),
          const SizedBox(height: 10),
          _DeltaRow(
            label: 'Gastos',
            delta: comparison.expenseDelta,
            positiveIsGood: false,
          ),
          const SizedBox(height: 10),
          _DeltaRow(
            label: 'Flujo neto',
            delta: comparison.netFlowDelta,
            positiveIsGood: true,
          ),
          if (comparison.topRising.isNotEmpty ||
              comparison.topFalling.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
                height: 1, color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 14),
          ],
          if (comparison.topRising.isNotEmpty) ...[
            const _CategorySectionLabel(label: 'Mayores alzas'),
            const SizedBox(height: 8),
            ...comparison.topRising.map(
              (d) => _CategoryDeltaRow(delta: d, isRising: true),
            ),
          ],
          if (comparison.topFalling.isNotEmpty) ...[
            if (comparison.topRising.isNotEmpty) const SizedBox(height: 12),
            const _CategorySectionLabel(label: 'Mayores bajas'),
            const SizedBox(height: 8),
            ...comparison.topFalling.map(
              (d) => _CategoryDeltaRow(delta: d, isRising: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  const _DeltaRow({
    required this.label,
    required this.delta,
    required this.positiveIsGood,
  });

  final String label;
  final double delta;
  final bool positiveIsGood;

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final isGood = positiveIsGood ? isPositive : !isPositive;
    final color = delta == 0
        ? AppTheme.onSurfaceMuted
        : isGood
            ? AppTheme.success
            : AppTheme.expense;
    final icon = isPositive
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
        ),
        if (delta != 0)
          Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          delta == 0
              ? '—'
              : '${delta > 0 ? '+' : ''}${AppFormatters.formatCurrency(delta)}',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CategorySectionLabel extends StatelessWidget {
  const _CategorySectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.manrope(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppTheme.onSurfaceMuted,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _CategoryDeltaRow extends StatelessWidget {
  const _CategoryDeltaRow({required this.delta, required this.isRising});

  final CategoryDelta delta;
  final bool isRising;

  @override
  Widget build(BuildContext context) {
    final color = isRising ? AppTheme.expense : AppTheme.success;
    final pct = delta.deltaPercent == -100
        ? '−100%'
        : '${delta.deltaPercent > 0 ? '+' : ''}${delta.deltaPercent.toStringAsFixed(0)}%';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              delta.categoryName,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          Text(
            pct,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Proyección ────────────────────────────────────────────────────────────────

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.projection});

  final MonthProjectionEntity projection;

  @override
  Widget build(BuildContext context) {
    final reliabilityColor = switch (projection.reliability) {
      ProjectionReliability.low => AppTheme.expense,
      ProjectionReliability.medium => AppTheme.warning,
      ProjectionReliability.high => AppTheme.success,
    };
    final reliabilityLabel = switch (projection.reliability) {
      ProjectionReliability.low =>
        'Baja confiabilidad · Pocos días de datos',
      ProjectionReliability.medium => 'Confiabilidad media',
      ProjectionReliability.high => 'Alta confiabilidad',
    };

    return _ReportCard(
      title: 'Proyección de cierre',
      icon: Icons.trending_up_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: reliabilityColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          reliabilityLabel,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: reliabilityColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Día ${projection.daysElapsed} de ${projection.totalDays}',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 12),
          _ProjectionRow(
            label: 'Gasto actual',
            value: projection.currentExpense,
            isProjected: false,
          ),
          const SizedBox(height: 8),
          _ProjectionRow(
            label: 'Gasto proyectado',
            value: projection.projectedExpense,
            isProjected: true,
            color: AppTheme.expense,
          ),
          const SizedBox(height: 8),
          _ProjectionRow(
            label: 'Ingreso proyectado',
            value: projection.projectedIncome,
            isProjected: true,
            color: AppTheme.income,
          ),
          const SizedBox(height: 8),
          _ProjectionRow(
            label: 'Flujo proyectado',
            value: projection.projectedNetFlow,
            isProjected: true,
            color: projection.projectedNetFlow >= 0
                ? AppTheme.success
                : AppTheme.expense,
          ),
          if (projection.budgetsAtRisk.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 15, color: AppTheme.warning),
                const SizedBox(width: 6),
                Text(
                  'Presupuestos en riesgo',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...projection.budgetsAtRisk.map(
              (r) => _BudgetRiskRow(risk: r),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectionRow extends StatelessWidget {
  const _ProjectionRow({
    required this.label,
    required this.value,
    required this.isProjected,
    this.color,
  });

  final String label;
  final double value;
  final bool isProjected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
        ),
        Text(
          AppFormatters.formatCurrency(value),
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: isProjected ? FontWeight.w700 : FontWeight.w500,
            color: color ?? AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _BudgetRiskRow extends StatelessWidget {
  const _BudgetRiskRow({required this.risk});

  final BudgetRisk risk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              risk.categoryName,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          Text(
            '+${risk.overagePercent.toStringAsFixed(0)}% sobre límite',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Insights ──────────────────────────────────────────────────────────────────

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.insights});

  final List<AnalyticsInsightEntity> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const _ReportCard(
        title: 'Insights',
        icon: Icons.lightbulb_outline_rounded,
        child: _NoDataState(
          message:
              'Registra más movimientos para ver insights automáticos.',
        ),
      );
    }

    return _ReportCard(
      title: 'Insights',
      icon: Icons.lightbulb_outline_rounded,
      child: Column(
        children: insights
            .map((i) => _InsightRow(insight: i))
            .toList(),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final AnalyticsInsightEntity insight;

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.severity) {
      InsightSeverity.positive => AppTheme.success,
      InsightSeverity.warning => AppTheme.warning,
      InsightSeverity.neutral => AppTheme.onSurfaceMuted,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insight.message,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
