import '../entities/category_entity.dart';
import '../repositories/categories_repository.dart';

class GetArchivedCategories {
  const GetArchivedCategories(this._repository);

  final CategoriesRepository _repository;

  Future<List<CategoryEntity>> call() {
    return _repository.getArchivedCategories();
  }
}
