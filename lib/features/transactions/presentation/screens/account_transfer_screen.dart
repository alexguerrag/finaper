import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/formatters/currency_input_formatter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../accounts/di/accounts_registry.dart';
import '../../../accounts/domain/entities/account_entity.dart';
import '../../di/transactions_registry.dart';
import '../../domain/entities/account_transfer_entity.dart';
import '../../domain/usecases/create_account_transfer.dart';
import '../../domain/usecases/update_account_transfer.dart';

class AccountTransferScreen extends StatefulWidget {
  const AccountTransferScreen({
    super.key,
    this.initialTransferGroupId,
    this.initialFromAccountId,
    this.initialFromAccountName,
    this.initialToAccountId,
    this.initialToAccountName,
    this.initialAmount,
    this.initialDate,
    this.initialDescription,
    this.initialNote,
  });

  final String? initialTransferGroupId;
  final String? initialFromAccountId;
  final String? initialFromAccountName;
  final String? initialToAccountId;
  final String? initialToAccountName;
  final double? initialAmount;
  final DateTime? initialDate;
  final String? initialDescription;
  final String? initialNote;

  bool get isEditMode =>
      initialTransferGroupId != null &&
      initialTransferGroupId!.trim().isNotEmpty;

  @override
  State<AccountTransferScreen> createState() => _AccountTransferScreenState();
}

class _AccountTransferScreenState extends State<AccountTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  late final CreateAccountTransfer _createAccountTransfer;
  late final UpdateAccountTransfer _updateAccountTransfer;

  bool _isLoading = true;
  bool _isSaving = false;

  List<AccountEntity> _accounts = <AccountEntity>[];

  String? _fromAccountId;
  String? _toAccountId;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    _createAccountTransfer = TransactionsRegistry.module.createAccountTransfer;
    _updateAccountTransfer = TransactionsRegistry.module.updateAccountTransfer;
    _selectedDate = widget.initialDate ?? DateTime.now();
    _descriptionController.text = widget.initialDescription ?? '';
    _noteController.text = widget.initialNote ?? '';
    if (widget.initialAmount != null) {
      _amountController.text = ThousandsInputFormatter.formatForInput(
        widget.initialAmount!,
        decimalDigits: AppFormatters.currentCurrencyDecimalDigits,
      );
    }
    _loadAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await AccountsRegistry.module.getAccounts();

      if (!mounted) return;

      String? initialFrom = widget.initialFromAccountId;
      String? initialTo = widget.initialToAccountId;

      if (accounts.isNotEmpty && (initialFrom == null || initialFrom.isEmpty)) {
        initialFrom = accounts.first.id;
      }

      if (accounts.length > 1 && (initialTo == null || initialTo.isEmpty)) {
        final alternatives =
            accounts.where((account) => account.id != initialFrom).toList();
        initialTo = alternatives.isNotEmpty ? alternatives.first.id : null;
      }

      setState(() {
        _accounts = accounts;
        _fromAccountId = initialFrom;
        _toAccountId = initialTo;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('AccountTransferScreen _loadAccounts error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron cargar las cuentas.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  AccountEntity? _findAccountById(String? id) {
    if (id == null || id.isEmpty) return null;

    for (final account in _accounts) {
      if (account.id == id) {
        return account;
      }
    }

    return null;
  }

  Future<void> _pickDate() async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppTheme.primary,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (picked == null || !mounted) return;

      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    } catch (e, s) {
      debugPrint('AccountTransferScreen _pickDate error: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  Future<void> _submit() async {
    if (_isSaving || _isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final fromAccount = _findAccountById(_fromAccountId);
    final toAccount = _findAccountById(_toAccountId);

    if (fromAccount == null || toAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecciona cuentas válidas para la transferencia.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
      return;
    }

    if (fromAccount.id == toAccount.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La cuenta de origen y destino deben ser distintas.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
      return;
    }

    final amount = ThousandsInputFormatter.parse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ingresa un monto válido mayor a cero.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final transfer = AccountTransferEntity(
        fromAccountId: fromAccount.id,
        fromAccountName: fromAccount.name,
        toAccountId: toAccount.id,
        toAccountName: toAccount.name,
        amount: amount,
        date: _selectedDate,
        note: _noteController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (_isEditMode) {
        await _updateAccountTransfer(
          transferGroupId: widget.initialTransferGroupId!.trim(),
          transfer: transfer,
        );
      } else {
        await _createAccountTransfer(transfer);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Transferencia actualizada correctamente.'
                : 'Transferencia registrada correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } on FormatException catch (e, s) {
      debugPrint('AccountTransferScreen _submit format error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message,
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('AccountTransferScreen _submit error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'No se pudo actualizar la transferencia.'
                : 'No se pudo registrar la transferencia.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditMode ? 'Editar transferencia' : 'Transferir entre cuentas',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _accounts.length < 2
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Text(
                        'Necesitas al menos dos cuentas activas para poder transferir dinero entre ellas.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          color: AppTheme.onSurfaceMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                )
              : SafeArea(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
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
                                _isEditMode
                                    ? 'Editar movimiento interno'
                                    : 'Movimiento interno',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurfaceMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mueve saldo entre tus cuentas sin contaminar ingresos, gastos ni dashboard.',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: AppTheme.onSurface,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _fromAccountId,
                          decoration: const InputDecoration(
                            labelText: 'Cuenta origen',
                          ),
                          items: _accounts
                              .map(
                                (account) => DropdownMenuItem<String>(
                                  value: account.id,
                                  child: Text(account.name),
                                ),
                              )
                              .toList(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona una cuenta de origen';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _fromAccountId = value;
                              if (_toAccountId == value) {
                                final alternatives = _accounts
                                    .where((account) => account.id != value)
                                    .toList();
                                _toAccountId = alternatives.isNotEmpty
                                    ? alternatives.first.id
                                    : null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _toAccountId,
                          decoration: const InputDecoration(
                            labelText: 'Cuenta destino',
                          ),
                          items: _accounts
                              .map(
                                (account) => DropdownMenuItem<String>(
                                  value: account.id,
                                  child: Text(account.name),
                                ),
                              )
                              .toList(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona una cuenta de destino';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _toAccountId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Builder(builder: (context) {
                          final dec =
                              AppFormatters.currentCurrencyDecimalDigits;
                          return TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              ThousandsInputFormatter(decimalDigits: dec),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Monto',
                              hintText: dec == 0 ? '0' : '0,00',
                              prefixText: '\$ ',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa un monto';
                              }
                              final parsed = ThousandsInputFormatter.parse(
                                  value.trim());
                              if (parsed == null) {
                                return 'Escribe un monto válido';
                              }
                              if (parsed <= 0) {
                                return 'El monto debe ser mayor a cero';
                              }
                              return null;
                            },
                          );
                        }),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción corta',
                            hintText: 'Ej. Transferencia a ahorros',
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: AppTheme.onSurfaceMuted,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Fecha: ${_formatDate(_selectedDate)}',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Cambiar',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _noteController,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Nota opcional',
                            hintText: 'Agrega contexto si lo necesitas',
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.swap_horiz_rounded),
                          label: Text(
                            _isSaving
                                ? (_isEditMode
                                    ? 'Actualizando transferencia...'
                                    : 'Registrando transferencia...')
                                : (_isEditMode
                                    ? 'Guardar cambios'
                                    : 'Registrar transferencia'),
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
