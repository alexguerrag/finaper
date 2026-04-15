import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/enums/category_kind.dart';
import '../models/category_model.dart';

abstract class CategoriesLocalDataSource {
  Future<List<CategoryModel>> getCategoriesByKind({
    required CategoryKind kind,
  });

  Future<CategoryModel> createCategory(CategoryModel category);

  Future<CategoryModel> updateCategory(CategoryModel category);
}

class CategoriesLocalDataSourceImpl implements CategoriesLocalDataSource {
  const CategoriesLocalDataSourceImpl(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<CategoryModel>> getCategoriesByKind({
    required CategoryKind kind,
  }) async {
    try {
      final db = await _databaseHelper.database;

      final result = await db.query(
        'categories',
        where: 'kind = ?',
        whereArgs: [kind.value],
        orderBy: 'name ASC',
      );

      return result.map(CategoryModel.fromMap).toList();
    } catch (e, s) {
      debugPrint('getCategoriesByKind error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      final db = await _databaseHelper.database;

      await db.insert(
        'categories',
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return category;
    } catch (e, s) {
      debugPrint('createCategory error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    try {
      final db = await _databaseHelper.database;

      await db.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );

      return category;
    } catch (e, s) {
      debugPrint('updateCategory error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
