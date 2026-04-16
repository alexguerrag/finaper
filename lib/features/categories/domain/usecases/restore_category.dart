import '../repositories/categories_repository.dart';

class RestoreCategory {
  const RestoreCategory(this._repository);

  final CategoriesRepository _repository;

  Future<void> call(String categoryId) {
    return _repository.restoreCategory(categoryId);
  }
}
