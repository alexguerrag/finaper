import '../../../../core/enums/category_kind.dart';
import '../entities/category_entity.dart';
import '../repositories/categories_repository.dart';

class GetCategoriesByKind {
  const GetCategoriesByKind(this._repository);

  final CategoriesRepository _repository;

  Future<List<CategoryEntity>> call({
    required CategoryKind kind,
  }) {
    return _repository.getCategoriesByKind(
      kind: kind,
    );
  }
}
