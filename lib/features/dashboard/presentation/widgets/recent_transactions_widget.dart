import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

class RecentTransactionsWidget extends StatelessWidget {
  const RecentTransactionsWidget({super.key});

  static final List<Map<String, dynamic>> _txMaps = [
    {
      'description': 'Salario mensual',
      'category': 'Salario',
      'amount': 4820.00,
      'isIncome': true,
      'date': '20 mar',
      'icon': Icons.work_rounded,
      'color': const Color(0xFF2ECC71),
    },
    {
      'description': 'Supermercado La Comer',
      'category': 'Alimentación',
      'amount': -156.80,
      'isIncome': false,
      'date': '19 mar',
      'icon': Icons.restaurant_rounded,
      'color': const Color(0xFFE67E22),
    },
    {
      'description': 'Netflix + Spotify',
      'category': 'Entretenimiento',
      'amount': -28.50,
      'isIncome': false,
      'date': '18 mar',
      'icon': Icons.movie_rounded,
      'color': const Color(0xFF9B59B6),
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.transactions);
                      },
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
              ...List.generate(_txMaps.length, (i) {
                final tx = _txMaps[i];
                final isLast = i == _txMaps.length - 1;

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
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: (tx['color'] as Color).withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              tx['icon'] as IconData,
                              size: 18,
                              color: tx['color'] as Color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx['description'] as String,
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
                                  '${tx['category']} · ${tx['date']}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    color: AppTheme.onSurfaceMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tx['isIncome'] as bool
                                ? '+\$${(tx['amount'] as double).toStringAsFixed(2)}'
                                : '-\$${(tx['amount'] as double).abs().toStringAsFixed(2)}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tx['isIncome'] as bool
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
