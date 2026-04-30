import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../di/analytics_registry.dart';
import '../../domain/entities/cash_flow_entity.dart';
import '../../domain/entities/ledger_entity.dart';
import '../../domain/entities/savings_rate_entity.dart';
import '../controllers/premium_reports_controller.dart';

class PremiumReportsScreen extends StatefulWidget {
  const PremiumReportsScreen({super.key});

  @override
  State<PremiumReportsScreen> createState() => _PremiumReportsScreenState();
}

class _PremiumReportsScreenState extends State<PremiumReportsScreen> {
  late final PremiumReportsController _controller;
  late final DateTime _month;

  @override
  void initState() {
    super.initState();
    _controller = AnalyticsRegistry.module.controller;
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _controller.load(_month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(
          'Reportes',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
          ),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _SavingsRateCard(data: reports.savingsRate),
                const SizedBox(height: 16),
                _CashFlowCard(data: reports.cashFlow),
                const SizedBox(height: 16),
                _LedgerCard(
                  data: reports.ledger,
                  currentPeriod: _controller.ledgerPeriod,
                  onPeriodChanged: _controller.setLedgerPeriod,
                ),
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
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          Padding(
            padding: const EdgeInsets.all(18),
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
    return Text(
      message,
      style: GoogleFonts.manrope(
        fontSize: 13,
        color: AppTheme.onSurfaceMuted,
        height: 1.5,
      ),
    );
  }
}

// ── Tasa de ahorro ────────────────────────────────────────────────────────────

class _SavingsRateCard extends StatelessWidget {
  const _SavingsRateCard({required this.data});

  final SavingsRateEntity data;

  @override
  Widget build(BuildContext context) {
    if (data.income == 0) {
      return const _ReportCard(
        title: 'Tasa de ahorro',
        child: _NoDataState(
          message: 'Sin ingresos registrados este mes.',
        ),
      );
    }

    final isPositive = data.rate >= 0;
    final rateColor = isPositive ? const Color(0xFF35E879) : AppTheme.expense;
    final rateText =
        '${isPositive ? '' : '−'}${data.rate.abs().toStringAsFixed(1)}%';

    final delta = data.rateDelta;

    return _ReportCard(
      title: 'Tasa de ahorro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rateText,
                style: GoogleFonts.manrope(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: rateColor,
                  height: 1,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _DeltaBadge(delta: delta, higherIsGood: true),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isPositive
                ? 'Ahorraste ${AppFormatters.formatCurrency(data.savedAmount)} de tus ingresos'
                : 'Gastaste más de lo que ingresaste este mes',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 14),
          _AmountRow(
            label: 'Ingresos del mes',
            amount: data.income,
            color: const Color(0xFF35E879),
          ),
          const SizedBox(height: 8),
          _AmountRow(
            label: 'Gastos del mes',
            amount: data.expense,
            color: AppTheme.expense,
          ),
          const SizedBox(height: 8),
          _AmountRow(
            label: 'Resultado',
            amount: data.savedAmount,
            color: rateColor,
            bold: true,
          ),
        ],
      ),
    );
  }
}

// ── Tabla de flujo de efectivo ────────────────────────────────────────────────

class _CashFlowCard extends StatelessWidget {
  const _CashFlowCard({required this.data});

  final CashFlowEntity data;

  @override
  Widget build(BuildContext context) {
    final hasData = data.income.count > 0 || data.expense.count > 0;

    if (!hasData) {
      return const _ReportCard(
        title: 'Flujo de efectivo',
        child: _NoDataState(
          message: 'Sin movimientos registrados este mes.',
        ),
      );
    }

    return _ReportCard(
      title: 'Flujo de efectivo',
      child: Column(
        children: [
          _CashFlowTable(data: data),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 14),
          _AmountRow(
            label: 'Flujo neto del mes',
            amount: data.netFlow,
            color: data.netFlow >= 0 ? const Color(0xFF35E879) : AppTheme.expense,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _CashFlowTable extends StatelessWidget {
  const _CashFlowTable({required this.data});

  final CashFlowEntity data;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
      },
      children: [
        _tableHeader(),
        _tableRow(
          label: 'Cantidad',
          income: data.income.count.toString(),
          expense: data.expense.count.toString(),
          incomeColor: AppTheme.onSurface,
          expenseColor: AppTheme.onSurface,
          isShaded: true,
        ),
        _tableRow(
          label: 'Promedio / día',
          income: AppFormatters.formatCurrency(data.income.dailyAverage),
          expense: AppFormatters.formatCurrency(data.expense.dailyAverage),
          incomeColor: const Color(0xFF35E879),
          expenseColor: AppTheme.expense,
        ),
        _tableRow(
          label: 'Promedio / registro',
          income: AppFormatters.formatCurrency(
              data.income.perTransactionAverage),
          expense: AppFormatters.formatCurrency(
              data.expense.perTransactionAverage),
          incomeColor: const Color(0xFF35E879),
          expenseColor: AppTheme.expense,
          isShaded: true,
        ),
        _tableRow(
          label: 'Total',
          income: AppFormatters.formatCurrency(data.income.total),
          expense: AppFormatters.formatCurrency(data.expense.total),
          incomeColor: const Color(0xFF35E879),
          expenseColor: AppTheme.expense,
          bold: true,
        ),
      ],
    );
  }

  TableRow _tableHeader() {
    return TableRow(
      children: [
        const SizedBox.shrink(),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Ingresos',
            textAlign: TextAlign.right,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF35E879),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Gastos',
            textAlign: TextAlign.right,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.expense,
            ),
          ),
        ),
      ],
    );
  }

  TableRow _tableRow({
    required String label,
    required String income,
    required String expense,
    required Color incomeColor,
    required Color expenseColor,
    bool isShaded = false,
    bool bold = false,
  }) {
    final weight =
        bold ? FontWeight.w800 : FontWeight.w500;
    final labelColor =
        bold ? AppTheme.onSurface : AppTheme.onSurfaceMuted;

    return TableRow(
      decoration: isShaded
          ? BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: weight,
              color: labelColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            income,
            textAlign: TextAlign.right,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: weight,
              color: incomeColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            expense,
            textAlign: TextAlign.right,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: weight,
              color: expenseColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Libro de ingresos y gastos ────────────────────────────────────────────────

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({
    required this.data,
    required this.currentPeriod,
    required this.onPeriodChanged,
  });

  final LedgerEntity data;
  final LedgerPeriod currentPeriod;
  final void Function(LedgerPeriod) onPeriodChanged;

  static const _periods = [
    (LedgerPeriod.days7, '7 días'),
    (LedgerPeriod.days30, '30 días'),
    (LedgerPeriod.thisMonth, 'Este mes'),
  ];

  @override
  Widget build(BuildContext context) {
    final hasData =
        data.incomeRows.isNotEmpty || data.expenseRows.isNotEmpty;

    return _ReportCard(
      title: 'Libro de ingresos y gastos',
      trailing: _PeriodSelector(
        current: currentPeriod,
        periods: _periods,
        onChanged: onPeriodChanged,
      ),
      child: hasData
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.incomeRows.isNotEmpty) ...[
                  _LedgerSectionHeader(
                    label: 'Ingresos',
                    total: data.totalIncome,
                    color: const Color(0xFF35E879),
                  ),
                  const SizedBox(height: 8),
                  ...data.incomeRows.map(
                    (r) => _LedgerRow(
                      row: r,
                      color: const Color(0xFF35E879),
                    ),
                  ),
                ],
                if (data.incomeRows.isNotEmpty && data.expenseRows.isNotEmpty)
                  const SizedBox(height: 16),
                if (data.expenseRows.isNotEmpty) ...[
                  _LedgerSectionHeader(
                    label: 'Gastos',
                    total: data.totalExpense,
                    color: AppTheme.expense,
                  ),
                  const SizedBox(height: 8),
                  ...data.expenseRows.map(
                    (r) => _LedgerRow(
                      row: r,
                      color: AppTheme.expense,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Divider(
                    height: 1, color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 14),
                _AmountRow(
                  label: 'Flujo del período',
                  amount: data.netFlow,
                  color: data.netFlow >= 0
                      ? const Color(0xFF35E879)
                      : AppTheme.expense,
                  bold: true,
                ),
              ],
            )
          : const _NoDataState(
              message: 'Sin movimientos en el período seleccionado.',
            ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.current,
    required this.periods,
    required this.onChanged,
  });

  final LedgerPeriod current;
  final List<(LedgerPeriod, String)> periods;
  final void Function(LedgerPeriod) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: periods.map((entry) {
        final (period, label) = entry;
        final selected = current == period;
        return GestureDetector(
          onTap: () => onChanged(period),
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color:
                    selected ? AppTheme.primary : AppTheme.onSurfaceMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LedgerSectionHeader extends StatelessWidget {
  const _LedgerSectionHeader({
    required this.label,
    required this.total,
    required this.color,
  });

  final String label;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceMuted,
            letterSpacing: 0.4,
          ),
        ),
        const Spacer(),
        Text(
          AppFormatters.formatCurrency(total),
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.row, required this.color});

  final LedgerCategoryRow row;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.categoryName,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          Text(
            '${row.count} mov.',
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppFormatters.formatCurrency(row.amount),
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

// ── Shared row widgets ────────────────────────────────────────────────────────

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
  });

  final String label;
  final double amount;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
            ),
          ),
        ),
        Text(
          AppFormatters.formatCurrency(amount),
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.delta, required this.higherIsGood});

  final double delta;
  final bool higherIsGood;

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final isGood = higherIsGood ? isPositive : !isPositive;
    final color = isGood ? const Color(0xFF35E879) : AppTheme.expense;
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$sign${delta.toStringAsFixed(1)}pp vs mes anterior',
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
