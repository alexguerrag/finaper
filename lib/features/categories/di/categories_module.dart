import '../../../app/di/app_module.dart';
import '../../../core/database/database_helper.dart';
import '../data/local/categories_local_datasource.dart';
import '../data/repositories/categories_repository_impl.dart';
import '../domain/repositories/categories_repository.dart';
import '../domain/usecases/create_category.dart';
import '../domain/usecases/get_categories_by_kind.dart';

class CategoriesModule implements AppModule {
  late final CategoriesLocalDataSource localDataSource;
  late final CategoriesRepository repository;
  late final GetCategoriesByKind getCategoriesByKind;
  late final CreateCategory createCategory;

  final DatabaseHelper _databaseHelper;

  CategoriesModule({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<void> register() async {
    localDataSource = CategoriesLocalDataSourceImpl(_databaseHelper);
    repository = CategoriesRepositoryImpl(localDataSource);
    getCategoriesByKind = GetCategoriesByKind(repository);
    createCategory = CreateCategory(repository);
  }
}
