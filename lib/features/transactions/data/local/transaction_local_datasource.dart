import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/account_transfer_entity.dart';
import '../../domain/entities/transaction_entry_type.dart';
import '../models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<TransactionModel> insertTransaction(TransactionModel transaction);
  Future<TransactionModel> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<void> deleteTransactionsByTransferGroup(String transferGroupId);
  Future<List<TransactionModel>> createTransfer(AccountTransferEntity transfer);
  Future<void> updateTransfer({
    required String transferGroupId,
    required AccountTransferEntity transfer,
  });
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  const TransactionLocalDataSourceImpl(this.dbHelper);

  final DatabaseHelper dbHelper;

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final db = await dbHelper.database;
      final maps = await db.query(
        'transactions',
        orderBy: 'date DESC, created_at DESC',
      );

      return List<TransactionModel>.generate(
        maps.length,
        (index) => TransactionModel.fromMap(maps[index]),
      );
    } catch (e, s) {
      debugPrint('getTransactions error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<TransactionModel> insertTransaction(
    TransactionModel transaction,
  ) async {
    try {
      final db = await dbHelper.database;

      await db.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return transaction;
    } catch (e, s) {
      debugPrint('insertTransaction datasource error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
    TransactionModel transaction,
  ) async {
    try {
      final db = await dbHelper.database;

      await db.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      return transaction;
    } catch (e, s) {
      debugPrint('updateTransaction datasource error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      final db = await dbHelper.database;

      await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, s) {
      debugPrint('deleteTransaction datasource error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteTransactionsByTransferGroup(String transferGroupId) async {
    try {
      final normalized = transferGroupId.trim();
      if (normalized.isEmpty) {
        throw const FormatException(
          'El grupo de transferencia no es válido.',
        );
      }

      final db = await dbHelper.database;

      await db.delete(
        'transactions',
        where: 'transfer_group_id = ?',
        whereArgs: [normalized],
      );
    } catch (e, s) {
      debugPrint('deleteTransactionsByTransferGroup datasource error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<List<TransactionModel>> createTransfer(
    AccountTransferEntity transfer,
  ) async {
    try {
      final normalizedDescription = transfer.description.trim();
      final normalizedNote = transfer.note.trim();

      if (transfer.fromAccountId == transfer.toAccountId) {
        throw const FormatException(
          'La cuenta de origen y destino deben ser distintas.',
        );
      }

      if (transfer.amount <= 0) {
        throw const FormatException(
          'El monto de la transferencia debe ser mayor a cero.',
        );
      }

      final db = await dbHelper.database;
      final now = DateTime.now();
      final transferGroupId = 'trf_${now.microsecondsSinceEpoch.toString()}';

      // Ambas patas comparten el mismo createdAt para que aparezcan juntas
      // en el ordenamiento y se perciban como un único evento atómico.
      final outgoing = TransactionModel(
        id: '${transferGroupId}_out',
        accountId: transfer.fromAccountId,
        accountName: transfer.fromAccountName,
        description: normalizedDescription.isNotEmpty
            ? normalizedDescription
            : 'Transferencia a ${transfer.toAccountName}',
        categoryId: DatabaseHelper.transferExpenseCategoryId,
        category: DatabaseHelper.transferExpenseCategoryName,
        amount: transfer.amount,
        isIncome: false,
        date: transfer.date,
        createdAt: now,
        note: normalizedNote,
        color: Colors.blueGrey.withValues(alpha: 1.0),
        entryType: TransactionEntryType.transferOut,
        transferGroupId: transferGroupId,
        counterpartyAccountId: transfer.toAccountId,
        counterpartyAccountName: transfer.toAccountName,
      );

      final incoming = TransactionModel(
        id: '${transferGroupId}_in',
        accountId: transfer.toAccountId,
        accountName: transfer.toAccountName,
        description: normalizedDescription.isNotEmpty
            ? normalizedDescription
            : 'Transferencia desde ${transfer.fromAccountName}',
        categoryId: DatabaseHelper.transferIncomeCategoryId,
        category: DatabaseHelper.transferIncomeCategoryName,
        amount: transfer.amount,
        isIncome: true,
        date: transfer.date,
        createdAt: now,
        note: normalizedNote,
        color: Colors.blueGrey.withValues(alpha: 1.0),
        entryType: TransactionEntryType.transferIn,
        transferGroupId: transferGroupId,
        counterpartyAccountId: transfer.fromAccountId,
        counterpartyAccountName: transfer.fromAccountName,
      );

      await db.transaction((txn) async {
        await txn.insert(
          'transactions',
          outgoing.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.insert(
          'transactions',
          incoming.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

      return [outgoing, incoming];
    } catch (e, s) {
      debugPrint('createTransfer datasource error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> updateTransfer({
    required String transferGroupId,
    required AccountTransferEntity transfer,
  }) async {
    try {
      final normalizedGroupId = transferGroupId.trim();
      final normalizedDescription = transfer.description.trim();
      final normalizedNote = transfer.note.trim();

      if (normalizedGroupId.isEmpty) {
        throw const FormatException(
          'El grupo de transferencia no es válido.',
        );
      }

      if (transfer.fromAccountId == transfer.toAccountId) {
        throw const FormatException(
          'La cuenta de origen y destino deben ser distintas.',
        );
      }

      if (transfer.amount <= 0) {
        throw const FormatException(
          'El monto de la transferencia debe ser mayor a cero.',
        );
      }

      final db = await dbHelper.database;

      final rows = await db.query(
        'transactions',
        where: 'transfer_group_id = ?',
        whereArgs: [normalizedGroupId],
      );

      if (rows.length != 2) {
        throw const FormatException(
          'No se pudo encontrar la transferencia completa para editar.',
        );
      }

      TransactionModel? outgoing;
      TransactionModel? incoming;

      for (final row in rows) {
        final model = TransactionModel.fromMap(row);
        if (model.entryType == TransactionEntryType.transferOut) {
          outgoing = model;
        } else if (model.entryType == TransactionEntryType.transferIn) {
          incoming = model;
        }
      }

      if (outgoing == null || incoming == null) {
        throw const FormatException(
          'La transferencia está incompleta o dañada.',
        );
      }

      // Preservar createdAt original de cada pata: la edición no altera
      // el momento en que se creó la transferencia.
      final updatedOutgoing = TransactionModel(
        id: outgoing.id,
        accountId: transfer.fromAccountId,
        accountName: transfer.fromAccountName,
        description: normalizedDescription.isNotEmpty
            ? normalizedDescription
            : 'Transferencia a ${transfer.toAccountName}',
        categoryId: DatabaseHelper.transferExpenseCategoryId,
        category: DatabaseHelper.transferExpenseCategoryName,
        amount: transfer.amount,
        isIncome: false,
        date: transfer.date,
        createdAt: outgoing.createdAt,
        note: normalizedNote,
        color: Colors.blueGrey.withValues(alpha: 1.0),
        entryType: TransactionEntryType.transferOut,
        transferGroupId: normalizedGroupId,
        counterpartyAccountId: transfer.toAccountId,
        counterpartyAccountName: transfer.toAccountName,
      );

      final updatedIncoming = TransactionModel(
        id: incoming.id,
        accountId: transfer.toAccountId,
        accountName: transfer.toAccountName,
        description: normalizedDescription.isNotEmpty
            ? normalizedDescription
            : 'Transferencia desde ${transfer.fromAccountName}',
        categoryId: DatabaseHelper.transferIncomeCategoryId,
        category: DatabaseHelper.transferIncomeCategoryName,
        amount: transfer.amount,
        isIncome: true,
        date: transfer.date,
        createdAt: incoming.createdAt,
        note: normalizedNote,
        color: Colors.blueGrey.withValues(alpha: 1.0),
        entryType: TransactionEntryType.transferIn,
        transferGroupId: normalizedGroupId,
        counterpartyAccountId: transfer.fromAccountId,
        counterpartyAccountName: transfer.fromAccountName,
      );

      await db.transaction((txn) async {
        await txn.update(
          'transactions',
          updatedOutgoing.toMap(),
          where: 'id = ?',
          whereArgs: [updatedOutgoing.id],
        );
        await txn.update(
          'transactions',
          updatedIncoming.toMap(),
          where: 'id = ?',
          whereArgs: [updatedIncoming.id],
        );
      });
    } catch (e, s) {
      debugPrint('updateTransfer datasource error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
