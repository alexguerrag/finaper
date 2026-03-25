import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';

class BalanceHeroWidget extends StatefulWidget {
  const BalanceHeroWidget({
    super.key,
    this.balanceOverride,
  });

  final double? balanceOverride;

  @override
  State<BalanceHeroWidget> createState() => _BalanceHeroWidgetState();
}

class _BalanceHeroWidgetState extends State<BalanceHeroWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _countAnim;

  bool _balanceVisible = true;

  double get _balance => widget.balanceOverride ?? 2847.50;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _configureAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant BalanceHeroWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.balanceOverride != widget.balanceOverride) {
      _configureAnimation();
      _controller.forward(from: 0);
    }
  }

  void _configureAnimation() {
    _countAnim = Tween<double>(
      begin: 0,
      end: _balance,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
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
                    'Balance actual',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _balanceVisible
                    ? AnimatedBuilder(
                        key: const ValueKey('visible'),
                        animation: _controller,
                        builder: (context, child) {
                          return Text(
                            AppFormatters.formatCurrency(_countAnim.value),
                            style: GoogleFonts.manrope(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          );
                        },
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
              const SizedBox(height: 6),
              Text(
                'Calculado desde tus transacciones guardadas',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
