import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/goal_model.dart';

abstract class GoalsLocalDataSource {
  Future<List<GoalModel>> getGoals({
    bool includeCompleted = true,
  });

  Future<GoalModel> createGoal(GoalModel goal);

  Future<GoalModel> updateGoal(GoalModel goal);

  Future<void> deleteGoal(String id);
}

class GoalsLocalDataSourceImpl implements GoalsLocalDataSource {
  const GoalsLocalDataSourceImpl(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<GoalModel>> getGoals({
    bool includeCompleted = true,
  }) async {
    try {
      final db = await _databaseHelper.database;

      final result = await db.query(
        'goals',
        where: includeCompleted ? null : 'is_completed = ?',
        whereArgs: includeCompleted ? null : [0],
        orderBy: 'is_completed ASC, updated_at DESC',
      );

      return result.map(GoalModel.fromMap).toList();
    } catch (e, s) {
      debugPrint('getGoals error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<GoalModel> createGoal(GoalModel goal) async {
    try {
      final db = await _databaseHelper.database;

      await db.insert(
        'goals',
        goal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return goal;
    } catch (e, s) {
      debugPrint('createGoal error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<GoalModel> updateGoal(GoalModel goal) async {
    try {
      final db = await _databaseHelper.database;

      await db.update(
        'goals',
        goal.toMap(),
        where: 'id = ?',
        whereArgs: [goal.id],
      );

      return goal;
    } catch (e, s) {
      debugPrint('updateGoal error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      final db = await _databaseHelper.database;

      await db.delete(
        'goals',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, s) {
      debugPrint('deleteGoal error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
