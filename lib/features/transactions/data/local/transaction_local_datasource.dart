import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/transaction_model.dart';

class TransactionLocalDataSource {
  static Database? _database;
  static const _databaseName = 'finaper.db';
  static const _databaseVersion = 2;
  static const _tableName = 'transactions';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_tableName ADD COLUMN is_income INTEGER NOT NULL DEFAULT 0',
          );

          await db.execute(
            'ALTER TABLE $_tableName ADD COLUMN note TEXT NOT NULL DEFAULT ""',
          );
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        is_income INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT ""
      )
    ''');
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final result = await db.query(
      _tableName,
      orderBy: 'date DESC',
    );

    return result.map(TransactionModel.fromMap).toList();
  }

  Future<TransactionModel> insertTransaction(TransactionModel model) async {
    final db = await database;

    final id = await db.insert(
      _tableName,
      model.toMap()..remove('id'),
    );

    return TransactionModel(
      id: id,
      description: model.description,
      category: model.category,
      amount: model.amount,
      isIncome: model.isIncome,
      date: model.date,
      note: model.note,
    );
  }

  Future<TransactionModel> updateTransaction(TransactionModel model) async {
    final db = await database;

    await db.update(
      _tableName,
      model.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [model.id],
    );

    return model;
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;

    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
