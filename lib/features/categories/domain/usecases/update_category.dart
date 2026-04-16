import '../entities/category_entity.dart';
import '../repositories/categories_repository.dart';

class UpdateCategory {
  const UpdateCategory(this._repository);

  final CategoriesRepository _repository;

  Future<CategoryEntity> call(CategoryEntity category) =>
      _repository.updateCategory(category);
}
