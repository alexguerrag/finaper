import '../../../../core/enums/category_kind.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/categories_repository.dart';
import '../local/categories_local_datasource.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  const CategoriesRepositoryImpl(this._localDataSource);

  final CategoriesLocalDataSource _localDataSource;

  @override
  Future<List<CategoryEntity>> getCategoriesByKind({
    required CategoryKind kind,
  }) {
    return _localDataSource.getCategoriesByKind(
      kind: kind,
    );
  }
}
