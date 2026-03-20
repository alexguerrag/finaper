import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class BalanceHeroWidget extends StatefulWidget {
  const BalanceHeroWidget({super.key});

  @override
  State<BalanceHeroWidget> createState() => _BalanceHeroWidgetState();
}

class _BalanceHeroWidgetState extends State<BalanceHeroWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnim;
  bool _balanceVisible = true;

  static const double _balance = 2847.50;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _countAnim = Tween<double>(
      begin: 0,
      end: _balance,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.18),
                AppTheme.primary.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance del mes',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.income.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              size: 12,
                              color: AppTheme.income,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+12.4%',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.income,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _balanceVisible = !_balanceVisible;
                          });
                        },
                        child: Icon(
                          _balanceVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _balanceVisible
                    ? AnimatedBuilder(
                        key: const ValueKey('visible'),
                        animation: _countAnim,
                        builder: (_, _) => Text(
                          '\$${_countAnim.value.toStringAsFixed(2)}',
                          style: GoogleFonts.manrope(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        '••••••',
                        key: const ValueKey('hidden'),
                        style: GoogleFonts.manrope(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.40),
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ahorro: 18.3% del ingreso · Marzo 2026',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso del mes',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  Text(
                    '20 de 31 días',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 20 / 31,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primary,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
