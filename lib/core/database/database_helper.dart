import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  static const String _databaseName = 'finaper.db';
  static const int _databaseVersion = 2;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e, s) {
      debugPrint('Database open error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transactions (
          id TEXT PRIMARY KEY,
          description TEXT NOT NULL,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          is_income INTEGER NOT NULL,
          date TEXT NOT NULL,
          note TEXT,
          color_value INTEGER NOT NULL
        )
      ''');

      await _createIndexes(db);
    } catch (e, s) {
      debugPrint('Database create error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 2) {
        await _createIndexes(db);
      }
    } catch (e, s) {
      debugPrint('Database migration error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(is_income)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category)',
    );
  }

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    try {
      final db = await database;
      return await db.insert(
        'transactions',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, s) {
      debugPrint('insertTransaction error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryAllTransactions() async {
    try {
      final db = await database;
      return await db.query(
        'transactions',
        orderBy: 'date DESC',
      );
    } catch (e, s) {
      debugPrint('queryAllTransactions error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<int> updateTransaction(
    String id,
    Map<String, dynamic> row,
  ) async {
    try {
      final db = await database;
      return await db.update(
        'transactions',
        row,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, s) {
      debugPrint('updateTransaction error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<int> deleteTransaction(String id) async {
    try {
      final db = await database;
      return await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, s) {
      debugPrint('deleteTransaction error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      final db = _database;
      if (db != null) {
        await db.close();
        _database = null;
      }
    } catch (e, s) {
      debugPrint('Database close error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
