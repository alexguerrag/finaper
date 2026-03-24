import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../accounts/presentation/screens/accounts_screen.dart';
import '../../../categories/presentation/screens/categories_screen.dart';

class CatalogsScreen extends StatelessWidget {
  const CatalogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            'Catálogos',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Cuentas'),
              Tab(text: 'Categorías'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AccountsScreen(),
            CategoriesScreen(),
          ],
        ),
      ),
    );
  }
}
