import '../../../../core/database/database_helper.dart';
import '../models/transaction_model.dart';
import 'package:sqflite/sqflite.dart'; // <--- Falta este

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<TransactionModel> insertTransaction(TransactionModel transaction);
  Future<TransactionModel> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final DatabaseHelper dbHelper;

  TransactionLocalDataSourceImpl(this.dbHelper);

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('transactions', orderBy: 'date DESC');

    // Optimización: Generación de lista inmutable y tipada
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  @override
  Future<TransactionModel> insertTransaction(
      TransactionModel transaction) async {
    final db = await dbHelper.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Evita duplicados por ID
    );
    return transaction;
  }

  @override
  Future<TransactionModel> updateTransaction(
      TransactionModel transaction) async {
    final db = await dbHelper.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    return transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
