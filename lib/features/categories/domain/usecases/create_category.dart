import '../entities/category_entity.dart';
import '../repositories/categories_repository.dart';

class CreateCategory {
  const CreateCategory(this._repository);

  final CategoriesRepository _repository;

  Future<CategoryEntity> call(CategoryEntity category) {
    return _repository.createCategory(category);
  }
}
