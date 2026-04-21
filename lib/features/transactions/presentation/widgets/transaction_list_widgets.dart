import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transaction_model.dart';
import '../controllers/transaction_list_controller.dart';

enum TxCardAction { edit, delete }

// ── filter chip ───────────────────────────────────────────────────────────────

class TxTypeFilterChip extends StatelessWidget {
  const TxTypeFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.70)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppTheme.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── active filter badge ───────────────────────────────────────────────────────

class TxActiveFilterBadge extends StatelessWidget {
  const TxActiveFilterBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.onSurface,
        ),
      ),
    );
  }
}

// ── adaptive summary card ─────────────────────────────────────────────────────

class TxAdaptiveSummaryCard extends StatelessWidget {
  const TxAdaptiveSummaryCard({
    super.key,
    required this.filter,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalNet,
    required this.visibleCount,
    required this.summaryValue,
    required this.onClearFilters,
  });

  final TransactionTypeFilter filter;
  final double totalIncome;
  final double totalExpense;
  final double totalNet;
  final int visibleCount;
  final double summaryValue;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (filter == TransactionTypeFilter.all) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TxSummaryItem(
                    label: 'Ingresos',
                    value: totalIncome,
                    color: AppTheme.income,
                  ),
                ),
                Expanded(
                  child: TxSummaryItem(
                    label: 'Gastos',
                    value: totalExpense,
                    color: AppTheme.expense,
                  ),
                ),
                Expanded(
                  child: TxSummaryItem(
                    label: 'Balance',
                    value: totalNet,
                    color: totalNet >= 0 ? AppTheme.income : AppTheme.expense,
                  ),
                ),
              ],
            ),
            if (onClearFilters != null) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(
                    'Limpiar filtros',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final isIncome = filter == TransactionTypeFilter.income;
    final title = isIncome ? 'Ingresos visibles' : 'Gastos visibles';
    final accentColor = isIncome ? AppTheme.income : AppTheme.expense;
    final subtitle = visibleCount == 1
        ? '1 movimiento en pantalla'
        : '$visibleCount movimientos en pantalla';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppFormatters.formatCurrency(summaryValue.abs()),
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onClearFilters != null)
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(
                'Limpiar',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

// ── summary item ──────────────────────────────────────────────────────────────

class TxSummaryItem extends StatelessWidget {
  const TxSummaryItem({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final prefix = value < 0 ? '-' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$prefix${AppFormatters.formatCurrency(value.abs())}',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── section header ────────────────────────────────────────────────────────────

class TxSectionHeader extends StatelessWidget {
  const TxSectionHeader({
    super.key,
    required this.label,
    required this.count,
    required this.income,
    required this.expense,
  });

  final String label;
  final int count;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count mov.',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ),
          if (income > 0) ...[
            const SizedBox(width: 10),
            Text(
              '+${AppFormatters.formatCurrency(income)}',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.income,
              ),
            ),
          ],
          if (expense > 0) ...[
            const SizedBox(width: 8),
            Text(
              '-${AppFormatters.formatCurrency(expense)}',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.expense,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── transaction card ──────────────────────────────────────────────────────────

class TxCard extends StatelessWidget {
  const TxCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionModel item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final note = item.note.trim();
    final hasNote = note.isNotEmpty;
    final amountColor = item.isIncome ? AppTheme.income : AppTheme.expense;
    final iconColor = item.color ?? amountColor;
    final formatted = AppFormatters.formatCurrency(item.amount.abs());
    final signedAmount = '${item.isIncome ? '+' : '-'}$formatted';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item.isTransfer
                        ? Icons.swap_horiz_rounded
                        : item.isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (item.isTransfer)
                            const TxMetaBadge(
                              icon: Icons.swap_horiz_rounded,
                              label: 'Transferencia',
                            ),
                          TxMetaBadge(
                            icon: Icons.category_rounded,
                            label: item.category,
                          ),
                          TxMetaBadge(
                            icon: Icons.account_balance_wallet_rounded,
                            label: item.accountName,
                          ),
                          TxMetaBadge(
                            icon: Icons.calendar_today_rounded,
                            label: AppFormatters.formatShortDate(item.date),
                          ),
                        ],
                      ),
                      if (hasNote) ...[
                        const SizedBox(height: 10),
                        Text(
                          note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            height: 1.35,
                            color: AppTheme.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      signedAmount,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    PopupMenuButton<TxCardAction>(
                      tooltip: 'Acciones',
                      color: AppTheme.surfaceElevated,
                      padding: EdgeInsets.zero,
                      splashRadius: 18,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      icon: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: AppTheme.onSurfaceMuted,
                        ),
                      ),
                      onSelected: (action) {
                        switch (action) {
                          case TxCardAction.edit:
                            onEdit();
                          case TxCardAction.delete:
                            onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: TxCardAction.edit,
                          child: Text(
                            'Editar',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: TxCardAction.delete,
                          child: Text(
                            'Eliminar',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.expense,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── meta badge ────────────────────────────────────────────────────────────────

class TxMetaBadge extends StatelessWidget {
  const TxMetaBadge({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.onSurfaceMuted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── empty state ───────────────────────────────────────────────────────────────

class TxEmptyState extends StatelessWidget {
  const TxEmptyState({
    super.key,
    required this.hasActiveFilters,
    required this.onClearFilters,
    required this.onAddTransaction,
  });

  final bool hasActiveFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters
                ? 'No encontramos movimientos'
                : 'Todavía no tienes transacciones',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilters
                ? 'Prueba con otros filtros o limpia la búsqueda actual.'
                : 'Comienza registrando tu primer ingreso o gasto.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              height: 1.35,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              if (hasActiveFilters)
                OutlinedButton.icon(
                  onPressed: onClearFilters,
                  style: OutlinedButton.styleFrom(
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(
                    'Limpiar filtros',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  ),
                ),
              FilledButton.icon(
                onPressed: onAddTransaction,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Nueva transacción',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
