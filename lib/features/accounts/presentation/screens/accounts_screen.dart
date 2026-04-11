import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/enums/account_type.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/account_model.dart';
import '../../di/accounts_registry.dart';
import '../../domain/entities/account_balance_entity.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/usecases/create_account.dart';
import '../../domain/usecases/get_account_balances.dart';
import '../../domain/usecases/update_account.dart';
import '../widgets/add_account_sheet.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late final GetAccountBalances _getAccountBalances;
  late final CreateAccount _createAccount;
  late final UpdateAccount _updateAccount;

  bool _isLoading = true;
  List<AccountBalanceEntity> _accountBalances = <AccountBalanceEntity>[];

  @override
  void initState() {
    super.initState();
    _getAccountBalances = AccountsRegistry.module.getAccountBalances;
    _createAccount = AccountsRegistry.module.createAccount;
    _updateAccount = AccountsRegistry.module.updateAccount;
    _loadAccountBalances();
  }

  double get _consolidatedBalance {
    return _accountBalances.fold<double>(
      0,
      (sum, item) => sum + item.currentBalance,
    );
  }

  Future<void> _loadAccountBalances() async {
    try {
      final balances = await _getAccountBalances();

      if (!mounted) return;

      setState(() {
        _accountBalances = balances;
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
      await _loadAccountBalances();

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

  Future<void> _openEditSheet(AccountEntity account) async {
    final result = await showModalBottomSheet<AccountModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAccountSheet(
        initialAccount: account,
      ),
    );

    if (result == null) return;

    try {
      await _updateAccount(result);
      await _loadAccountBalances();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cuenta actualizada correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Update account error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo actualizar la cuenta.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  String _formatSignedCurrency(double value) {
    final formatted = AppFormatters.formatCurrency(value.abs());

    if (value > 0) {
      return '+$formatted';
    }

    if (value < 0) {
      return '-$formatted';
    }

    return AppFormatters.formatCurrency(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAccountBalances,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Saldo real por cuenta derivado desde saldo inicial y movimientos registrados.',
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
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo total consolidado',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppFormatters.formatCurrency(_consolidatedBalance),
                  style: GoogleFonts.manrope(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_accountBalances.isEmpty)
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
            ..._accountBalances.map(
              (item) {
                final account = item.account;
                final isPositiveFlow = item.netFlow >= 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        _openEditSheet(account);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color:
                                        account.color.withValues(alpha: 0.16),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.formatCurrency(
                                        item.currentBalance,
                                      ),
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Saldo actual',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        color: AppTheme.onSurfaceMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: AppTheme.onSurfaceMuted,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Saldo inicial ${AppFormatters.formatCurrency(account.initialBalance)}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: AppTheme.onSurfaceMuted,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isPositiveFlow
                                            ? AppTheme.income
                                            : AppTheme.expense)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: (isPositiveFlow
                                              ? AppTheme.income
                                              : AppTheme.expense)
                                          .withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Text(
                                    'Flujo ${_formatSignedCurrency(item.netFlow)}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isPositiveFlow
                                          ? AppTheme.income
                                          : AppTheme.expense,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
