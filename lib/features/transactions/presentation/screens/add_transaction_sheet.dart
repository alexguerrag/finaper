// C:\dev\projects\finaper\lib\features\transactions\presentation\screens\add_transaction_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/transaction_model.dart';

class AddTransactionSheet extends StatefulWidget {
  final Future<void> Function(TransactionModel transaction) onAdd;

  const AddTransactionSheet({super.key, required this.onAdd});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isIncome = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) return;

    setState(() {
      _isSaving = true;
    });

    final tx = TransactionModel(
      id: null,
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      amount: amount,
      isIncome: _isIncome,
      date: DateTime.now(),
      note: _noteController.text.trim(),
    );

    try {
      await widget.onAdd(tx);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la transacción'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outline,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Nueva transacción',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _typeChip(
                          label: 'Gasto',
                          selected: !_isIncome,
                          onTap: () => setState(() => _isIncome = false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _typeChip(
                          label: 'Ingreso',
                          selected: _isIncome,
                          onTap: () => setState(() => _isIncome = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _descriptionController,
                    label: 'Descripción',
                    hint: 'Ej: Supermercado',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa una descripción';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _categoryController,
                    label: 'Categoría',
                    hint: 'Ej: Alimentación',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa una categoría';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _amountController,
                    label: 'Monto',
                    hint: 'Ej: 125.50',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un monto';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Monto inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _noteController,
                    label: 'Nota',
                    hint: 'Opcional',
                    requiredField: false,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Guardar transacción',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
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

  Widget _typeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool requiredField = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: requiredField ? validator : null,
          style: GoogleFonts.manrope(color: AppTheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }
}
