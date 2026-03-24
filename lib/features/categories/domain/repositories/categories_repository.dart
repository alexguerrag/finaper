import '../../../../core/enums/category_kind.dart';
import '../entities/category_entity.dart';

abstract class CategoriesRepository {
  Future<List<CategoryEntity>> getCategoriesByKind({
    required CategoryKind kind,
  });

  Future<CategoryEntity> createCategory(CategoryEntity category);
}
