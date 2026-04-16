import '../../../../core/enums/category_kind.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/categories_repository.dart';
import '../local/categories_local_datasource.dart';
import '../models/category_model.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  const CategoriesRepositoryImpl(this._localDataSource);

  final CategoriesLocalDataSource _localDataSource;

  @override
  Future<List<CategoryEntity>> getCategoriesByKind({
    required CategoryKind kind,
  }) {
    return _localDataSource.getCategoriesByKind(kind: kind);
  }

  @override
  Future<List<CategoryEntity>> getArchivedCategories() {
    return _localDataSource.getArchivedCategories();
  }

  @override
  Future<bool> hasActiveRecurring(String categoryId) {
    return _localDataSource.hasActiveRecurring(categoryId);
  }

  @override
  Future<CategoryEntity> createCategory(CategoryEntity category) {
    return _localDataSource.createCategory(
      CategoryModel.fromEntity(category),
    );
  }

  @override
  Future<CategoryEntity> updateCategory(CategoryEntity category) {
    return _localDataSource.updateCategory(
      CategoryModel.fromEntity(category),
    );
  }

  @override
  Future<void> archiveCategory(String id) {
    return _localDataSource.archiveCategory(id);
  }

  @override
  Future<void> restoreCategory(String id) {
    return _localDataSource.restoreCategory(id);
  }
}
