import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/enums/category_kind.dart';
import '../../../../core/enums/recurrence_frequency.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../accounts/di/accounts_registry.dart';
import '../../../accounts/domain/entities/account_entity.dart';
import '../../../categories/di/categories_registry.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../data/models/recurring_transaction_model.dart';

class AddRecurringTransactionSheet extends StatefulWidget {
  const AddRecurringTransactionSheet({super.key});

  @override
  State<AddRecurringTransactionSheet> createState() =>
      _AddRecurringTransactionSheetState();
}

class _AddRecurringTransactionSheetState
    extends State<AddRecurringTransactionSheet> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _intervalController =
      TextEditingController(text: '1');

  bool _isIncome = false;
  bool _isLoading = true;

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;

  List<AccountEntity> _accounts = <AccountEntity>[];
  List<CategoryEntity> _categories = <CategoryEntity>[];

  String? _selectedAccountId;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
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
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('Recurring bootstrap error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
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
      _isLoading = true;
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
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('Recurring reload categories error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2040),
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
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2040),
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
      _endDate = picked;
    });
  }

  AccountEntity? _selectedAccount() {
    for (final account in _accounts) {
      if (account.id == _selectedAccountId) return account;
    }
    return null;
  }

  CategoryEntity? _selectedCategory() {
    for (final category in _categories) {
      if (category.id == _selectedCategoryId) return category;
    }
    return null;
  }

  void _submit() {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final account = _selectedAccount();
    final category = _selectedCategory();

    if (account == null || category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecciona una cuenta y categoría válidas.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
      return;
    }

    final amount =
        double.parse(_amountController.text.trim().replaceAll(',', '.'));
    final intervalValue = int.parse(_intervalController.text.trim());
    final now = DateTime.now();

    final model = RecurringTransactionModel(
      id: 'rec-${now.millisecondsSinceEpoch}',
      accountId: account.id,
      accountName: account.name,
      description: _descriptionController.text.trim(),
      categoryId: category.id,
      categoryName: category.name,
      amount: amount,
      isIncome: _isIncome,
      note: _noteController.text.trim(),
      color: category.color.withValues(alpha: 1.0),
      frequency: _frequency,
      intervalValue: intervalValue,
      startDate: _startDate,
      endDate: _endDate,
      nextRunDate: _startDate,
      lastGeneratedDate: null,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    Navigator.of(context).pop(model);
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
          child: _isLoading && _accounts.isEmpty && _categories.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
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
                          'Nueva recurrente',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Se generará automáticamente cuando llegue su próxima fecha.',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.onSurfaceMuted,
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
                                onTap: () async {
                                  if (_isIncome) {
                                    setState(() {
                                      _isIncome = false;
                                    });
                                    await _reloadCategoriesForType();
                                  }
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
                                onTap: () async {
                                  if (!_isIncome) {
                                    setState(() {
                                      _isIncome = true;
                                    });
                                    await _reloadCategoriesForType();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
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
                            'rec-category-${_isIncome ? 'income' : 'expense'}-${_selectedCategoryId ?? 'empty'}',
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
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            hintText: 'Ej. Netflix, salario, alquiler',
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
                          decoration: const InputDecoration(
                            labelText: 'Monto',
                            hintText: 'Ej. 250.00',
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
                              return 'Debe ser mayor a cero';
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
                        DropdownButtonFormField<RecurrenceFrequency>(
                          initialValue: _frequency,
                          decoration: const InputDecoration(
                            labelText: 'Frecuencia',
                          ),
                          items: RecurrenceFrequency.values
                              .map(
                                (frequency) =>
                                    DropdownMenuItem<RecurrenceFrequency>(
                                  value: frequency,
                                  child: Text(frequency.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _frequency = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _intervalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Intervalo',
                            hintText: 'Ej. 1',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa un intervalo';
                            }

                            final parsed = int.tryParse(value.trim());

                            if (parsed == null) {
                              return 'Intervalo inválido';
                            }

                            if (parsed <= 0) {
                              return 'Debe ser mayor a cero';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickStartDate,
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
                                    'Inicio: ${_formatDate(_startDate)}',
                                    style: GoogleFonts.manrope(
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickEndDate,
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
                                const Icon(Icons.event_repeat_rounded),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _endDate == null
                                        ? 'Fin opcional'
                                        : 'Fin: ${_formatDate(_endDate!)}',
                                    style: GoogleFonts.manrope(
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (_endDate != null)
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _endDate = null;
                                      });
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  )
                                else
                                  const Icon(Icons.chevron_right_rounded),
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
                            labelText: 'Nota',
                            hintText: 'Comentario opcional',
                          ),
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
                              'Guardar recurrente',
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
