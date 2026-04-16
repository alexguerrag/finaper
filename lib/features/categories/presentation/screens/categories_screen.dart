import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/enums/category_kind.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/category_model.dart';
import '../../di/categories_registry.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/create_category.dart';
import '../../domain/usecases/get_categories_by_kind.dart';
import '../../domain/usecases/update_category.dart';
import '../widgets/add_category_sheet.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final GetCategoriesByKind _getCategoriesByKind;
  late final CreateCategory _createCategory;
  late final UpdateCategory _updateCategory;

  bool _isLoading = true;
  CategoryKind _selectedKind = CategoryKind.expense;
  List<CategoryEntity> _categories = <CategoryEntity>[];

  @override
  void initState() {
    super.initState();
    _getCategoriesByKind = CategoriesRegistry.module.getCategoriesByKind;
    _createCategory = CategoriesRegistry.module.createCategory;
    _updateCategory = CategoriesRegistry.module.updateCategory;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _getCategoriesByKind(
        kind: _selectedKind,
      );

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('CategoriesScreen load error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddSheet() async {
    final result = await showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(
        initialKind: _selectedKind,
      ),
    );

    if (result == null) return;

    try {
      await _createCategory(result);

      if (result.kind != _selectedKind) {
        setState(() {
          _selectedKind = result.kind;
          _isLoading = true;
        });
      }

      await _loadCategories();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Categoría creada correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Create category error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo crear la categoría.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _openEditSheet(CategoryEntity category) async {
    final result = await showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(
        initialKind: category.kind,
        initialCategory: category,
      ),
    );

    if (result == null) return;

    try {
      await _updateCategory(result);
      await _loadCategories();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Categoría actualizada correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Update category error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo actualizar la categoría.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _changeKind(CategoryKind kind) async {
    if (_selectedKind == kind) return;

    setState(() {
      _selectedKind = kind;
      _isLoading = true;
    });

    await _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gestiona categorías para clasificar ingresos y gastos.',
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
          Row(
            children: [
              _KindChip(
                label: 'Gastos',
                selected: _selectedKind == CategoryKind.expense,
                onTap: () => _changeKind(CategoryKind.expense),
              ),
              const SizedBox(width: 8),
              _KindChip(
                label: 'Ingresos',
                selected: _selectedKind == CategoryKind.income,
                onTap: () => _changeKind(CategoryKind.income),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_categories.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Todavía no hay categorías para este tipo.',
                style: GoogleFonts.manrope(
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            )
          else
            ..._categories.map(
              (category) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        IconData(
                          category.iconCode,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: category.color,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.isSystem ? 'Sistema' : 'Personalizada',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppTheme.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!category.isSystem)
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: AppTheme.onSurfaceMuted,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openEditSheet(category);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppTheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Editar',
                                  style: GoogleFonts.manrope(
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.onSurface,
          ),
        ),
      ),
    );
  }
}
