import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/app_settings_model.dart';

abstract class AppSettingsLocalDataSource {
  Future<AppSettingsModel> getAppSettings();

  Future<AppSettingsModel> saveAppSettings(AppSettingsModel settings);
}

class AppSettingsLocalDataSourceImpl implements AppSettingsLocalDataSource {
  const AppSettingsLocalDataSourceImpl(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  @override
  Future<AppSettingsModel> getAppSettings() async {
    try {
      final db = await _databaseHelper.database;

      final result = await db.query(
        'app_settings',
        limit: 1,
      );

      if (result.isEmpty) {
        final defaults = AppSettingsModel.defaults();

        await db.insert(
          'app_settings',
          defaults.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        return defaults;
      }

      return AppSettingsModel.fromMap(result.first);
    } catch (e, s) {
      debugPrint('getAppSettings error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<AppSettingsModel> saveAppSettings(AppSettingsModel settings) async {
    try {
      final db = await _databaseHelper.database;

      await db.insert(
        'app_settings',
        settings.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return settings;
    } catch (e, s) {
      debugPrint('saveAppSettings error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
