import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
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
  bool _showArchived = false;
  List<AccountBalanceEntity> _accountBalances = <AccountBalanceEntity>[];

  @override
  void initState() {
    super.initState();
    _getAccountBalances = AccountsRegistry.module.getAccountBalances;
    _createAccount = AccountsRegistry.module.createAccount;
    _updateAccount = AccountsRegistry.module.updateAccount;
    _loadAccountBalances();
  }

  List<AccountBalanceEntity> get _activeBalances =>
      _accountBalances.where((b) => !b.account.isArchived).toList();

  List<AccountBalanceEntity> get _archivedBalances =>
      _accountBalances.where((b) => b.account.isArchived).toList();

  double get _consolidatedBalance {
    return _activeBalances.fold<double>(
      0,
      (sum, item) => sum + item.currentBalance,
    );
  }

  bool get _canTransfer => _activeBalances.length >= 2;

  Future<void> _loadAccountBalances() async {
    try {
      final balances = await _getAccountBalances(includeArchived: true);

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

  Future<void> _openTransferFlow() async {
    if (!_canTransfer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Necesitas al menos dos cuentas activas para transferir.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
      return;
    }

    final didCreateTransfer = await Navigator.of(context).pushNamed(
      AppRoutes.accountTransfer,
    );

    if (didCreateTransfer == true) {
      await _loadAccountBalances();
    }
  }

  Future<void> _confirmArchiveAccount(AccountEntity account) async {
    final isArchived = account.isArchived;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: Text(
          isArchived ? 'Desarchivar cuenta' : 'Archivar cuenta',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArchived
                  ? '¿Quieres restaurar "${account.name}" como cuenta activa?'
                  : '¿Quieres archivar "${account.name}"?',
              style: GoogleFonts.manrope(color: AppTheme.onSurface),
            ),
            if (!isArchived) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'El historial de transacciones se conserva. La cuenta solo deja de aparecer en las vistas activas.',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: GoogleFonts.manrope()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isArchived ? 'Restaurar' : 'Archivar',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _updateAccount(
        account.copyWith(isArchived: !isArchived),
      );
      await _loadAccountBalances();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArchived
                ? 'Cuenta restaurada correctamente.'
                : 'Cuenta archivada correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Archive account error: $e');
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Cuentas',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _canTransfer ? _openTransferFlow : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(
                      _canTransfer
                          ? 'Transferir entre cuentas'
                          : 'Necesitas 2 cuentas para transferir',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                  if (_activeBalances.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.04)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 30,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Crea tu primera cuenta',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Las cuentas representan dónde tienes tu dinero: banco, efectivo o tarjeta.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              height: 1.45,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _openAddSheet,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              'Nueva cuenta',
                              style:
                                  GoogleFonts.manrope(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._activeBalances.map(
                      (item) => _buildAccountCard(item, isArchived: false),
                    ),
                  if (_archivedBalances.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showArchived = !_showArchived),
                      child: Row(
                        children: [
                          Icon(
                            _showArchived
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 18,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showArchived
                                ? 'Ocultar archivadas (${_archivedBalances.length})'
                                : 'Mostrar archivadas (${_archivedBalances.length})',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showArchived) ...[
                      const SizedBox(height: 8),
                      ..._archivedBalances.map(
                        (item) => _buildAccountCard(item, isArchived: true),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildAccountCard(AccountBalanceEntity item,
      {required bool isArchived}) {
    final account = item.account;
    final isPositiveFlow = item.netFlow >= 0;

    return Opacity(
      opacity: isArchived ? 0.55 : 1.0,
      child: Container(
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
            onTap: () => _openEditSheet(account),
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
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.formatCurrency(item.currentBalance),
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
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: AppTheme.onSurfaceMuted,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openEditSheet(account);
                          } else if (value == 'archive') {
                            _confirmArchiveAccount(account);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: AppTheme.onSurfaceMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Editar',
                                  style: GoogleFonts.manrope(),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'archive',
                            child: Row(
                              children: [
                                Icon(
                                  isArchived
                                      ? Icons.unarchive_rounded
                                      : Icons.archive_rounded,
                                  size: 18,
                                  color: AppTheme.onSurfaceMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isArchived ? 'Desarchivar' : 'Archivar',
                                  style: GoogleFonts.manrope(),
                                ),
                              ],
                            ),
                          ),
                        ],
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
      ),
    );
  }
}
