import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/enums/category_kind.dart';
import '../../../../core/icons/app_icon_catalog.dart';
import '../../../../core/theme/app_theme.dart';
import '../../di/categories_registry.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/get_archived_categories.dart';
import '../../domain/usecases/restore_category.dart';

class ArchivedCategoriesScreen extends StatefulWidget {
  const ArchivedCategoriesScreen({super.key});

  @override
  State<ArchivedCategoriesScreen> createState() =>
      _ArchivedCategoriesScreenState();
}

class _ArchivedCategoriesScreenState extends State<ArchivedCategoriesScreen> {
  late final GetArchivedCategories _getArchivedCategories;
  late final RestoreCategory _restoreCategory;

  bool _isLoading = true;
  List<CategoryEntity> _archived = <CategoryEntity>[];

  @override
  void initState() {
    super.initState();
    _getArchivedCategories = CategoriesRegistry.module.getArchivedCategories;
    _restoreCategory = CategoriesRegistry.module.restoreCategory;
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _getArchivedCategories();

      if (!mounted) return;
      setState(() {
        _archived = list;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('ArchivedCategoriesScreen load error: $e');
      debugPrintStack(stackTrace: s);
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmRestore(CategoryEntity category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: Text(
          'Restaurar categoría',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
          ),
        ),
        content: Text(
          '"${category.name}" volverá a aparecer en los pickers de nuevas transacciones, '
          'presupuestos y recurrentes.',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: GoogleFonts.manrope()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: Text(
              'Restaurar',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _restoreCategory(category.id);
      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${category.name}" restaurada correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Restore category error: $e');
      debugPrintStack(stackTrace: s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo restaurar la categoría.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Categorías archivadas',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _archived.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: AppTheme.onSurfaceMuted.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay categorías archivadas',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cuando archives una categoría personalizada aparecerá aquí.',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _archived.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final category = _archived[index];
                    return Container(
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
                              color: category.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              AppIconCatalog.resolve(category.iconCode),
                              color: category.color.withValues(alpha: 0.5),
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
                                    color: AppTheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category.kind.label,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppTheme.onSurfaceMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _confirmRestore(category),
                            icon: const Icon(
                              Icons.restore_rounded,
                              size: 16,
                            ),
                            label: Text(
                              'Restaurar',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
