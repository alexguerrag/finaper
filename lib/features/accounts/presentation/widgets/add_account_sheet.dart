import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/enums/account_type.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/account_model.dart';

class AddAccountSheet extends StatefulWidget {
  const AddAccountSheet({super.key});

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  AccountType _selectedType = AccountType.cash;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final account = AccountModel(
      id: 'acc-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      type: _selectedType,
      iconCode: _iconForType(_selectedType).codePoint,
      color: _colorForType(_selectedType).withValues(alpha: 1.0),
      isArchived: false,
      createdAt: DateTime.now(),
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
                    'Nueva cuenta',
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
                        'Guardar cuenta',
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
