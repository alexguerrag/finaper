import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class BudgetBarsWidget extends StatefulWidget {
  const BudgetBarsWidget({super.key});

  @override
  State<BudgetBarsWidget> createState() => _BudgetBarsWidgetState();
}

class _BudgetBarsWidgetState extends State<BudgetBarsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  static final List<Map<String, dynamic>> _budgetMaps = [
    {
      'category': 'Alimentación',
      'spent': 620.0,
      'limit': 800.0,
      'icon': Icons.restaurant_rounded,
      'color': const Color(0xFFE67E22),
    },
    {
      'category': 'Entretenimiento',
      'spent': 348.0,
      'limit': 400.0,
      'icon': Icons.movie_rounded,
      'color': const Color(0xFF9B59B6),
    },
    {
      'category': 'Transporte',
      'spent': 180.0,
      'limit': 300.0,
      'icon': Icons.directions_car_rounded,
      'color': const Color(0xFF3498DB),
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
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
              Text(
                'Presupuestos',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _anim,
                builder: (_, _) => Column(
                  children: _budgetMaps.map((b) {
                    final spent = b['spent'] as double;
                    final limit = b['limit'] as double;
                    final ratio = (spent / limit).clamp(0.0, 1.0);
                    final isWarning = ratio >= 0.8;
                    final color = isWarning
                        ? AppTheme.warning
                        : b['color'] as Color;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: (b['color'] as Color).withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(
                                  b['icon'] as IconData,
                                  size: 16,
                                  color: b['color'] as Color,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  b['category'] as String,
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                '\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: ratio * _anim.value,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${(ratio * 100).toStringAsFixed(0)}% utilizado',
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  color: color.withValues(alpha: 0.90),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
