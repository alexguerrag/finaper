//C:\dev\projects\finaper\lib\features\transactions\data\local\transaction_local_datasource.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/models/transaction_model.dart';

class TransactionLocalDataSource {
  static const _dbName = 'finaper.db';
  static const _tableName = 'transactions';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            id TEXT PRIMARY KEY,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            isIncome INTEGER NOT NULL,
            date TEXT NOT NULL,
            note TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'date DESC');

    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert(
      _tableName,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> seedIfEmpty(List<TransactionModel> seedData) async {
    final db = await database;
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    if (count > 0) return;

    final batch = db.batch();
    for (final tx in seedData) {
      batch.insert(
        _tableName,
        tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
