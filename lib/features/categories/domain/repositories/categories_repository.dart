import '../../../../core/enums/category_kind.dart';
import '../entities/category_entity.dart';

abstract class CategoriesRepository {
  Future<List<CategoryEntity>> getCategoriesByKind({
    required CategoryKind kind,
  });

  Future<List<CategoryEntity>> getArchivedCategories();

  Future<bool> hasActiveRecurring(String categoryId);

  Future<CategoryEntity> createCategory(CategoryEntity category);

  Future<CategoryEntity> updateCategory(CategoryEntity category);

  Future<void> archiveCategory(String id);

  Future<void> restoreCategory(String id);
}
