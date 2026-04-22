import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/enums/account_type.dart';
import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/formatters/currency_input_formatter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/account_model.dart';
import '../../domain/entities/account_entity.dart';

class AddAccountSheet extends StatefulWidget {
  const AddAccountSheet({
    super.key,
    this.initialAccount,
  });

  final AccountEntity? initialAccount;

  bool get isEditing => initialAccount != null;

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _initialBalanceController;

  late AccountType _selectedType;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAccount;
    _nameController = TextEditingController(
      text: initial?.name ?? '',
    );
    _initialBalanceController = TextEditingController(
      text: _formatInitialBalance(initial?.initialBalance ?? 0),
    );
    _selectedType = initial?.type ?? AccountType.cash;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  String _formatInitialBalance(double value) {
    return ThousandsInputFormatter.formatForInput(
      value,
      decimalDigits: AppFormatters.currentCurrencyDecimalDigits,
    );
  }

  IconData _iconForType(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.account_balance_wallet_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.savings:
        return Icons.savings_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.investment:
        return Icons.trending_up_rounded;
    }
  }

  Color _colorForType(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Colors.blue;
      case AccountType.bank:
        return Colors.indigo;
      case AccountType.savings:
        return Colors.green;
      case AccountType.creditCard:
        return Colors.deepPurple;
      case AccountType.investment:
        return Colors.teal;
    }
  }

  double _parseInitialBalance() {
    return ThousandsInputFormatter.parse(
          _initialBalanceController.text.trim(),
        ) ??
        0;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final initial = widget.initialAccount;

    final account = AccountModel(
      id: initial?.id ?? 'acc-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      type: _selectedType,
      iconCode: _iconForType(_selectedType).codePoint,
      color: _colorForType(_selectedType).withValues(alpha: 1.0),
      initialBalance: _parseInitialBalance(),
      isArchived: initial?.isArchived ?? false,
      createdAt: initial?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(account);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.isEditing ? 'Editar cuenta' : 'Nueva cuenta',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej. Banco principal, Efectivo, Tarjeta',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un nombre';
                      }
                      if (value.trim().length < 3) {
                        return 'Debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    final dec = AppFormatters.currentCurrencyDecimalDigits;
                    return TextFormField(
                      controller: _initialBalanceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        ThousandsInputFormatter(decimalDigits: dec),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Saldo inicial',
                        hintText: dec == 0 ? '0' : '0,00',
                        prefixText: '\$ ',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        final parsed =
                            ThousandsInputFormatter.parse(value.trim());
                        if (parsed == null) return 'Escribe un saldo válido';
                        if (parsed < 0) {
                          return 'Por ahora el saldo inicial no puede ser negativo';
                        }
                        return null;
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AccountType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de cuenta',
                    ),
                    items: AccountType.values
                        .map(
                          (type) => DropdownMenuItem<AccountType>(
                            value: type,
                            child: Text(type.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        widget.isEditing ? 'Guardar cambios' : 'Guardar cuenta',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
