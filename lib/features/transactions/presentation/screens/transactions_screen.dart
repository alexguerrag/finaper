import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Transacciones',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'Transactions Screen 🚀',
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
      ),
    );
  }
}
