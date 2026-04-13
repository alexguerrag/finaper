import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transaction_model.dart';

class TransactionDetailsSheet extends StatelessWidget {
  const TransactionDetailsSheet({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });

  final TransactionModel transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final isTransfer = transaction.isTransfer;
    final amountColor = isTransfer
        ? AppTheme.primary
        : (transaction.isIncome ? AppTheme.income : AppTheme.expense);
    final iconColor = transaction.color ?? amountColor;
    final note = transaction.note.trim();

    final typeLabel = isTransfer
        ? 'Transferencia'
        : (transaction.isIncome ? 'Ingreso' : 'Gasto');

    final typeIcon = isTransfer
        ? Icons.swap_horiz_rounded
        : (transaction.isIncome
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded);

    final primaryAccountLabel =
        transaction.entryType.storageValue == 'transfer_out'
            ? 'Cuenta origen'
            : transaction.entryType.storageValue == 'transfer_in'
                ? 'Cuenta destino'
                : 'Cuenta';

    final counterpartyLabel =
        transaction.entryType.storageValue == 'transfer_out'
            ? 'Cuenta destino'
            : transaction.entryType.storageValue == 'transfer_in'
                ? 'Cuenta origen'
                : 'Cuenta relacionada';

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      typeIcon,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: amountColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: amountColor.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Text(
                            typeLabel,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: amountColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          transaction.description,
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onSurface,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monto',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${transaction.isIncome ? '+' : '-'}${AppFormatters.formatCurrency(transaction.amount.abs())}',
                      style: GoogleFonts.manrope(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Detalle',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.category_rounded,
                label: 'Categoría',
                value: transaction.category,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.account_balance_wallet_rounded,
                label: primaryAccountLabel,
                value: transaction.accountName,
              ),
              if (isTransfer &&
                  (transaction.counterpartyAccountName?.trim().isNotEmpty ??
                      false)) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.swap_horiz_rounded,
                  label: counterpartyLabel,
                  value: transaction.counterpartyAccountName!.trim(),
                ),
              ],
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                label: 'Fecha',
                value: AppFormatters.formatShortDate(transaction.date),
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.sticky_note_2_rounded,
                  label: 'Nota',
                  value: note,
                  multiline: true,
                ),
              ],
              const SizedBox(height: 22),
              Text(
                'Acciones',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      label: Text(
                        'Editar',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDuplicate,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.content_copy_rounded),
                      label: Text(
                        'Duplicar',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onDelete,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.expense,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.delete_rounded),
                  label: Text(
                    isTransfer
                        ? 'Eliminar transferencia'
                        : 'Eliminar transacción',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                    height: multiline ? 1.35 : 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
