import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/enums/category_kind.dart';
import '../models/category_model.dart';

abstract class CategoriesLocalDataSource {
  /// Returns active (non-archived) categories for the given kind.
  Future<List<CategoryModel>> getCategoriesByKind({
    required CategoryKind kind,
  });

  /// Returns all archived categories, ordered by name.
  Future<List<CategoryModel>> getArchivedCategories();

  /// Returns true if the category has at least one active recurring transaction.
  Future<bool> hasActiveRecurring(String categoryId);

  Future<CategoryModel> createCategory(CategoryModel category);

  Future<CategoryModel> updateCategory(CategoryModel category);

  Future<void> archiveCategory(String id);

  Future<void> restoreCategory(String id);
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
        where: 'kind = ? AND is_archived = 0',
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
  Future<List<CategoryModel>> getArchivedCategories() async {
    try {
      final db = await _databaseHelper.database;

      final result = await db.query(
        'categories',
        where: 'is_archived = 1',
        orderBy: 'name ASC',
      );

      return result.map(CategoryModel.fromMap).toList();
    } catch (e, s) {
      debugPrint('getArchivedCategories error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<bool> hasActiveRecurring(String categoryId) async {
    try {
      final db = await _databaseHelper.database;

      final result = await db.query(
        'recurring_transactions',
        columns: ['id'],
        where: 'category_id = ? AND is_active = 1',
        whereArgs: [categoryId],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e, s) {
      debugPrint('hasActiveRecurring error: $e');
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

  @override
  Future<void> archiveCategory(String id) async {
    try {
      final db = await _databaseHelper.database;

      await db.update(
        'categories',
        {'is_archived': 1},
        where: 'id = ? AND is_system = 0',
        whereArgs: [id],
      );
    } catch (e, s) {
      debugPrint('archiveCategory error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> restoreCategory(String id) async {
    try {
      final db = await _databaseHelper.database;

      await db.update(
        'categories',
        {'is_archived': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, s) {
      debugPrint('restoreCategory error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
