import '../../../../core/database/database_helper.dart';
import '../../../../core/enums/category_kind.dart';
import '../models/category_model.dart';

abstract class CategoriesLocalDataSource {
  Future<List<CategoryModel>> getCategoriesByKind({
    required CategoryKind kind,
  });
}

class CategoriesLocalDataSourceImpl implements CategoriesLocalDataSource {
  const CategoriesLocalDataSourceImpl(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<CategoryModel>> getCategoriesByKind({
    required CategoryKind kind,
  }) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'categories',
      where: 'kind = ?',
      whereArgs: [kind.value],
      orderBy: 'name ASC',
    );

    return result.map(CategoryModel.fromMap).toList();
  }
}
