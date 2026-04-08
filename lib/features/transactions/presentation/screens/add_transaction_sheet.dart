import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/enums/category_kind.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../accounts/di/accounts_registry.dart';
import '../../../accounts/domain/entities/account_entity.dart';
import '../../../categories/di/categories_registry.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../data/models/transaction_model.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({
    super.key,
    required this.onAdd,
  });

  final Future<void> Function(TransactionModel transaction) onAdd;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isIncome = false;
  bool _isSaving = false;
  bool _isLoadingCoreData = true;

  DateTime _selectedDate = DateTime.now();

  List<AccountEntity> _accounts = <AccountEntity>[];
  List<CategoryEntity> _categories = <CategoryEntity>[];

  String? _selectedAccountId;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _bootstrapCoreData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapCoreData() async {
    setState(() {
      _isLoadingCoreData = true;
    });

    try {
      final accounts = await AccountsRegistry.module.getAccounts();
      final categories = await CategoriesRegistry.module.getCategoriesByKind(
        kind: _isIncome ? CategoryKind.income : CategoryKind.expense,
      );

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _categories = categories;
        _selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;
        _selectedCategoryId =
            categories.isNotEmpty ? categories.first.id : null;
        _isLoadingCoreData = false;
      });
    } catch (e, s) {
      debugPrint('AddTransactionSheet bootstrap error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoadingCoreData = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron cargar cuentas y categorías.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _reloadCategoriesForType() async {
    setState(() {
      _isLoadingCoreData = true;
    });

    try {
      final categories = await CategoriesRegistry.module.getCategoriesByKind(
        kind: _isIncome ? CategoryKind.income : CategoryKind.expense,
      );

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _selectedCategoryId =
            categories.isNotEmpty ? categories.first.id : null;
        _isLoadingCoreData = false;
      });
    } catch (e, s) {
      debugPrint('Reload categories error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoadingCoreData = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron recargar las categorías.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _handleTypeChange(bool value) async {
    if (_isIncome == value) return;

    setState(() {
      _isIncome = value;
    });

    await _reloadCategoriesForType();
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

      if (picked == null) return;

      setState(() {
        _selectedDate = picked;
      });
    } catch (e) {
      debugPrint('Date picker error: $e');
    }
  }

  Future<void> _submit() async {
    if (_isLoadingCoreData || _accounts.isEmpty || _categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Todavía no hay cuentas o categorías disponibles.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final selectedAccount = _accounts.where((a) => a.id == _selectedAccountId);
    final selectedCategory =
        _categories.where((c) => c.id == _selectedCategoryId);

    if (selectedAccount.isEmpty || selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecciona una cuenta y una categoría válidas.',
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
      final normalizedAmount =
          _amountController.text.trim().replaceAll(',', '.');
      final amount = double.parse(normalizedAmount);

      final account = selectedAccount.first;
      final category = selectedCategory.first;

      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        accountId: account.id,
        accountName: account.name,
        description: _descriptionController.text.trim(),
        categoryId: category.id,
        category: category.name,
        amount: amount,
        isIncome: _isIncome,
        date: _selectedDate,
        note: _noteController.text.trim(),
        color: category.color,
      );

      await widget.onAdd(transaction);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transacción guardada correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Add transaction submit error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la transacción.',
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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
            child: _isLoadingCoreData &&
                    _accounts.isEmpty &&
                    _categories.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Form(
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
                          'Nueva transacción',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _TypeCard(
                                title: 'Gasto',
                                icon: Icons.arrow_upward_rounded,
                                selected: !_isIncome,
                                color: AppTheme.expense,
                                onTap: () {
                                  _handleTypeChange(false);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TypeCard(
                                title: 'Ingreso',
                                icon: Icons.arrow_downward_rounded,
                                selected: _isIncome,
                                color: AppTheme.income,
                                onTap: () {
                                  _handleTypeChange(true);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'account-${_selectedAccountId ?? 'empty'}',
                          ),
                          initialValue: _selectedAccountId,
                          decoration: const InputDecoration(
                            labelText: 'Cuenta',
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
                              return 'Selecciona una cuenta';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _selectedAccountId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'category-${_isIncome ? 'income' : 'expense'}-${_selectedCategoryId ?? 'empty'}',
                          ),
                          initialValue: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                          ),
                          items: _categories
                              .map(
                                (category) => DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Text(category.name),
                                ),
                              )
                              .toList(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona una categoría';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            hintText: 'Ej. Supermercado, salario, taxi...',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa una descripción';
                            }
                            if (value.trim().length < 3) {
                              return 'Debe tener al menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Monto',
                            hintText: 'Ej. 250.50',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa un monto';
                            }

                            final normalized =
                                value.trim().replaceAll(',', '.');
                            final parsed = double.tryParse(normalized);

                            if (parsed == null) {
                              return 'Monto inválido';
                            }

                            if (parsed <= 0) {
                              return 'El monto debe ser mayor a cero';
                            }

                            return null;
                          },
                          onChanged: (value) {
                            final normalized = value.replaceAll(',', '.');
                            if (normalized != value) {
                              _amountController.value =
                                  _amountController.value.copyWith(
                                text: normalized,
                                selection: TextSelection.collapsed(
                                  offset: normalized.length,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Fecha: ${_formatDate(_selectedDate)}',
                                    style: GoogleFonts.manrope(
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _noteController,
                          minLines: 3,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Nota',
                            hintText: 'Comentario opcional',
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSaving || _isLoadingCoreData
                                ? null
                                : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Guardar transacción',
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

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
