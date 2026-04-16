import '../repositories/categories_repository.dart';

class ArchiveCategory {
  const ArchiveCategory(this._repository);

  final CategoriesRepository _repository;

  Future<void> call(String categoryId) {
    return _repository.archiveCategory(categoryId);
  }
}
