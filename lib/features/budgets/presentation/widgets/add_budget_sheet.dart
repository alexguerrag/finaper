import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/enums/category_kind.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../categories/di/categories_registry.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../data/models/budget_model.dart';

class AddBudgetSheet extends StatefulWidget {
  const AddBudgetSheet({
    super.key,
    required this.monthKey,
  });

  final String monthKey;

  @override
  State<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  List<CategoryEntity> _categories = <CategoryEntity>[];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadExpenseCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenseCategories() async {
    try {
      final categories = await CategoriesRegistry.module.getCategoriesByKind(
        kind: CategoryKind.expense,
      );

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _selectedCategoryId = null;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('AddBudgetSheet load categories error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron cargar las categorías.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (_isLoading || _isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final category = _categories
        .where((item) => item.id == _selectedCategoryId)
        .cast<CategoryEntity?>()
        .firstOrNull;

    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecciona una categoría válida.',
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
      final normalized = _amountController.text.trim().replaceAll(',', '.');
      final amount = double.parse(normalized);
      final now = DateTime.now();

      final budget = BudgetModel(
        id: 'budget-${category.id}-${widget.monthKey}',
        categoryId: category.id,
        categoryName: category.name,
        monthKey: widget.monthKey,
        amountLimit: amount,
        spentAmount: 0,
        color: category.color,
        createdAt: now,
        updatedAt: now,
      );

      if (!mounted) return;
      Navigator.of(context).pop(budget);
    } catch (e, s) {
      debugPrint('AddBudgetSheet submit error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo preparar el presupuesto.',
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasCategories = _categories.isNotEmpty;

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
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
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
                          'Nuevo presupuesto',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mes: ${widget.monthKey}. Elige primero la categoría correcta para evitar asignarlo al lugar equivocado.',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!hasCategories)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              'No hay categorías de gasto disponibles.',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppTheme.onSurfaceMuted,
                              ),
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Categoría de gasto',
                              hintText: 'Selecciona una categoría',
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
                        if (hasCategories && _selectedCategoryId != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Categoría seleccionada: ${_categories.firstWhere((item) => item.id == _selectedCategoryId).name}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: hasCategories,
                          decoration: const InputDecoration(
                            labelText: 'Límite mensual',
                            hintText: 'Ej. 500.00',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa un límite';
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
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                _isSaving || !hasCategories ? null : _submit,
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
                                    'Guardar presupuesto',
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
