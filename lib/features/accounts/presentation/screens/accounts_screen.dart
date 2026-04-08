import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/enums/account_type.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/account_model.dart';
import '../../di/accounts_registry.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/usecases/create_account.dart';
import '../../domain/usecases/get_accounts.dart';
import '../widgets/add_account_sheet.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late final GetAccounts _getAccounts;
  late final CreateAccount _createAccount;

  bool _isLoading = true;
  List<AccountEntity> _accounts = <AccountEntity>[];

  @override
  void initState() {
    super.initState();
    _getAccounts = AccountsRegistry.module.getAccounts;
    _createAccount = AccountsRegistry.module.createAccount;
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _getAccounts();

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('AccountsScreen load error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddSheet() async {
    final result = await showModalBottomSheet<AccountModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddAccountSheet(),
    );

    if (result == null) return;

    try {
      await _createAccount(result);
      await _loadAccounts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cuenta creada correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Create account error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo crear la cuenta.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAccounts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gestiona las cuentas disponibles para registrar movimientos.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _openAddSheet,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nueva'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_accounts.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Todavía no hay cuentas creadas.',
                style: GoogleFonts.manrope(
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            )
          else
            ..._accounts.map(
              (account) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: account.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        IconData(
                          account.iconCode,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: account.color,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            account.type.label,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
