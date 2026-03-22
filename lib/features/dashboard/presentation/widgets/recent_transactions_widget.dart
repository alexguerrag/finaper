// C:\dev\projects\finaper\lib\features\dashboard\presentation\widgets\recent_transactions_widget.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../transactions/data/models/transaction_model.dart';
import '../../../../core/theme/app_theme.dart';

class RecentTransactionsWidget extends StatelessWidget {
  final List<TransactionModel>? transactionsOverride;
  final VoidCallback? onSeeAll;

  const RecentTransactionsWidget({
    super.key,
    this.transactionsOverride,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final txs = transactionsOverride ?? [];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Últimas transacciones',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    InkWell(
                      onTap: onSeeAll,
                      child: Text(
                        'Ver todo',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (txs.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Text(
                    'Aún no tienes transacciones recientes',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                )
              else
                ...List.generate(txs.length, (i) {
                  final tx = txs[i];
                  final isLast = i == txs.length - 1;

                  return Column(
                    children: [
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.08),
                          indent: 20,
                          endIndent: 20,
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          12,
                          20,
                          isLast ? 20 : 12,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: tx.isIncome
                                  ? AppTheme.income.withValues(alpha: 0.2)
                                  : AppTheme.expense.withValues(alpha: 0.2),
                              child: Icon(
                                tx.isIncome
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: tx.isIncome
                                    ? AppTheme.income
                                    : AppTheme.expense,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.description,
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tx.category,
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      color: AppTheme.onSurfaceMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              tx.isIncome
                                  ? '+\$${tx.amount.toStringAsFixed(2)}'
                                  : '-\$${tx.amount.toStringAsFixed(2)}',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: tx.isIncome
                                    ? AppTheme.income
                                    : AppTheme.expense,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
