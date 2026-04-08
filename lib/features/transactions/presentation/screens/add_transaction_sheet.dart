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
    this.initialTransaction,
  });

  final Future<void> Function(TransactionModel transaction) onAdd;
  final TransactionModel? initialTransaction;

  bool get isEditing => initialTransaction != null;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

enum _QuickDateOption {
  today,
  yesterday,
  custom,
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
  _QuickDateOption _quickDateOption = _QuickDateOption.today;

  List<AccountEntity> _accounts = <AccountEntity>[];
  List<CategoryEntity> _categories = <CategoryEntity>[];

  String? _selectedAccountId;
  String? _selectedCategoryId;

  String? _lastExpenseCategoryId;
  String? _lastIncomeCategoryId;

  @override
  void initState() {
    super.initState();
    _hydrateInitialDraft();
    _bootstrapCoreData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _hydrateInitialDraft() {
    final initial = widget.initialTransaction;
    if (initial == null) return;

    _isIncome = initial.isIncome;
    _selectedDate = initial.date;
    _quickDateOption = _resolveQuickDateOption(initial.date);
    _descriptionController.text = initial.description;
    _amountController.text = _formatInitialAmount(initial.amount);
    _noteController.text = initial.note;
    _selectedAccountId = initial.accountId;
    _selectedCategoryId = initial.categoryId;

    if (initial.isIncome) {
      _lastIncomeCategoryId = initial.categoryId;
    } else {
      _lastExpenseCategoryId = initial.categoryId;
    }
  }

  String _formatInitialAmount(double value) {
    final asText = value.toStringAsFixed(2);
    if (asText.endsWith('.00')) {
      return value.toStringAsFixed(0);
    }
    return asText;
  }

  _QuickDateOption _resolveQuickDateOption(DateTime value) {
    final normalized = _dateOnly(value);
    final today = _dateOnly(DateTime.now());
    final yesterday = _dateOnly(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    if (_isSameDate(normalized, today)) {
      return _QuickDateOption.today;
    }

    if (_isSameDate(normalized, yesterday)) {
      return _QuickDateOption.yesterday;
    }

    return _QuickDateOption.custom;
  }

  Future<void> _bootstrapCoreData() async {
    setState(() {
      _isLoadingCoreData = true;
    });

    try {
      final accounts = await AccountsRegistry.module.getAccounts();
      final categories = await CategoriesRegistry.module.getCategoriesByKind(
        kind: _currentCategoryKind,
      );

      if (!mounted) return;

      final resolvedAccountId = _resolveAccountId(accounts);
      final resolvedCategoryId = _resolveCategoryId(categories);

      setState(() {
        _accounts = accounts;
        _categories = categories;
        _selectedAccountId = resolvedAccountId;
        _selectedCategoryId = resolvedCategoryId;
        _rememberCurrentCategorySelection(resolvedCategoryId);
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

  String? _resolveAccountId(List<AccountEntity> accounts) {
    if (accounts.isEmpty) return null;

    final alreadySelected = _selectedAccountId;
    if (alreadySelected != null &&
        accounts.any((account) => account.id == alreadySelected)) {
      return alreadySelected;
    }

    return accounts.first.id;
  }

  String? _resolveCategoryId(List<CategoryEntity> categories) {
    if (categories.isEmpty) return null;

    final preferredId = _preferredCategoryIdForCurrentType;
    if (preferredId != null &&
        categories.any((category) => category.id == preferredId)) {
      return preferredId;
    }

    final alreadySelected = _selectedCategoryId;
    if (alreadySelected != null &&
        categories.any((category) => category.id == alreadySelected)) {
      return alreadySelected;
    }

    return categories.first.id;
  }

  Future<void> _reloadCategoriesForType() async {
    setState(() {
      _isLoadingCoreData = true;
    });

    try {
      final categories = await CategoriesRegistry.module.getCategoriesByKind(
        kind: _currentCategoryKind,
      );

      if (!mounted) return;

      final resolvedCategoryId = _resolveCategoryId(categories);

      setState(() {
        _categories = categories;
        _selectedCategoryId = resolvedCategoryId;
        _rememberCurrentCategorySelection(resolvedCategoryId);
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

    _rememberCurrentCategorySelection(_selectedCategoryId);

    setState(() {
      _isIncome = value;
      _selectedCategoryId = null;
    });

    await _reloadCategoriesForType();
  }

  CategoryKind get _currentCategoryKind =>
      _isIncome ? CategoryKind.income : CategoryKind.expense;

  String? get _preferredCategoryIdForCurrentType =>
      _isIncome ? _lastIncomeCategoryId : _lastExpenseCategoryId;

  void _rememberCurrentCategorySelection(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return;

    if (_isIncome) {
      _lastIncomeCategoryId = categoryId;
    } else {
      _lastExpenseCategoryId = categoryId;
    }
  }

  void _selectToday() {
    setState(() {
      _selectedDate = _dateOnly(DateTime.now());
      _quickDateOption = _QuickDateOption.today;
    });
  }

  void _selectYesterday() {
    setState(() {
      _selectedDate = _dateOnly(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      _quickDateOption = _QuickDateOption.yesterday;
    });
  }

  Future<void> _pickCustomDate() async {
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
        _selectedDate = _dateOnly(picked);
        _quickDateOption = _resolveQuickDateOption(picked);
      });
    } catch (e, s) {
      debugPrint('Date picker error: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
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

    final account = _selectedAccount();
    final category = _selectedCategory();

    if (account == null || category == null) {
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

      final transaction = TransactionModel(
        id: widget.initialTransaction?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
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

      final successMessage = widget.isEditing
          ? 'Transacción actualizada correctamente.'
          : 'Transacción guardada correctamente.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successMessage,
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
            widget.isEditing
                ? 'No se pudo actualizar la transacción.'
                : 'No se pudo guardar la transacción.',
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Color get _accentColor => _isIncome ? AppTheme.income : AppTheme.expense;

  String get _sheetTitle =>
      widget.isEditing ? 'Editar transacción' : 'Nueva transacción';

  String get _sheetSubtitle => widget.isEditing
      ? 'Actualiza los datos de tu movimiento'
      : 'Registra un gasto o ingreso en segundos';

  String get _primaryButtonLabel {
    if (_isSaving) {
      return widget.isEditing ? 'Guardando cambios...' : 'Guardando...';
    }

    if (widget.isEditing) return 'Guardar cambios';
    return _isIncome ? 'Guardar ingreso' : 'Guardar gasto';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: _isLoadingCoreData && _accounts.isEmpty && _categories.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 56),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                                _sheetTitle,
                                style: GoogleFonts.manrope(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _sheetSubtitle,
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
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
                              const SizedBox(height: 18),
                              _AmountHeroField(
                                controller: _amountController,
                                accentColor: _accentColor,
                              ),
                              const SizedBox(height: 16),
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
                                    _rememberCurrentCategorySelection(value);
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
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
                              const SizedBox(height: 16),
                              Text(
                                'Fecha',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _QuickDateSelector(
                                selectedOption: _quickDateOption,
                                currentDate: _selectedDate,
                                onTodayTap: _selectToday,
                                onYesterdayTap: _selectYesterday,
                                onCustomTap: _pickCustomDate,
                                formatDate: _formatDate,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Concepto',
                                  hintText:
                                      'Ej. Supermercado, salario, taxi...',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Agrega un concepto';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Debe tener al menos 3 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _noteController,
                                minLines: 2,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Nota opcional',
                                  hintText:
                                      'Agrega un comentario si lo necesitas',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSaving || _isLoadingCoreData
                                ? null
                                : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(56),
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
                                    _primaryButtonLabel,
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _AmountHeroField extends StatelessWidget {
  const _AmountHeroField({
    required this.controller,
    required this.accentColor,
  });

  final TextEditingController controller;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        style: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppTheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: 'Monto',
          hintText: '0.00',
          prefixText: '\$ ',
          prefixStyle: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 8,
          ),
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Ingresa un monto';
          }

          final normalized = value.trim().replaceAll(',', '.');
          final parsed = double.tryParse(normalized);

          if (parsed == null) {
            return 'Escribe un monto válido';
          }

          if (parsed <= 0) {
            return 'El monto debe ser mayor a cero';
          }

          return null;
        },
        onChanged: (value) {
          final normalized = value.replaceAll(',', '.');
          if (normalized != value) {
            controller.value = controller.value.copyWith(
              text: normalized,
              selection: TextSelection.collapsed(
                offset: normalized.length,
              ),
            );
          }
        },
      ),
    );
  }
}

class _QuickDateSelector extends StatelessWidget {
  const _QuickDateSelector({
    required this.selectedOption,
    required this.currentDate,
    required this.onTodayTap,
    required this.onYesterdayTap,
    required this.onCustomTap,
    required this.formatDate,
  });

  final _QuickDateOption selectedOption;
  final DateTime currentDate;
  final VoidCallback onTodayTap;
  final VoidCallback onYesterdayTap;
  final VoidCallback onCustomTap;
  final String Function(DateTime date) formatDate;

  @override
  Widget build(BuildContext context) {
    final isCustom = selectedOption == _QuickDateOption.custom;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _QuickDateChip(
          label: 'Hoy',
          selected: selectedOption == _QuickDateOption.today,
          onTap: onTodayTap,
        ),
        _QuickDateChip(
          label: 'Ayer',
          selected: selectedOption == _QuickDateOption.yesterday,
          onTap: onYesterdayTap,
        ),
        _QuickDateChip(
          label: isCustom ? formatDate(currentDate) : 'Elegir fecha',
          selected: isCustom,
          onTap: onCustomTap,
          icon: Icons.calendar_month_rounded,
        ),
      ],
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  const _QuickDateChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.70)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? AppTheme.primary : AppTheme.onSurfaceMuted,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
              ),
            ),
          ],
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
