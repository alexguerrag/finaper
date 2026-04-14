import 'package:finaper/features/transactions/data/local/transaction_local_datasource.dart';
import 'package:finaper/features/transactions/data/models/transaction_model.dart';
import 'package:finaper/features/transactions/domain/entities/account_transfer_entity.dart';
import 'package:finaper/features/transactions/domain/entities/transaction_entry_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionLocalDataSource contract', () {
    late _InMemoryTransactionLocalDataSource datasource;

    setUp(() {
      datasource = _InMemoryTransactionLocalDataSource();
    });

    test('createTransfer inserts two linked transfer legs', () async {
      final result = await datasource.createTransfer(
        AccountTransferEntity(
          fromAccountId: 'acc-main',
          fromAccountName: 'Cuenta principal',
          toAccountId: 'acc-savings',
          toAccountName: 'Ahorros',
          amount: 25000,
          date: DateTime(2026, 4, 13),
          note: 'Mover ahorro',
          description: 'Transferencia a ahorros',
        ),
      );

      expect(result, hasLength(2));
      expect(result.first.transferGroupId, isNotEmpty);
      expect(result.first.transferGroupId, result.last.transferGroupId);
      expect(result.first.entryType, TransactionEntryType.transferOut);
      expect(result.last.entryType, TransactionEntryType.transferIn);

      final rows = await datasource.getTransactions();
      expect(
        rows.where(
            (item) => item.transferGroupId == result.first.transferGroupId),
        hasLength(2),
      );
    });

    test('deleteTransactionsByTransferGroup removes both transfer legs',
        () async {
      final created = await datasource.createTransfer(
        AccountTransferEntity(
          fromAccountId: 'acc-main',
          fromAccountName: 'Cuenta principal',
          toAccountId: 'acc-savings',
          toAccountName: 'Ahorros',
          amount: 30000,
          date: DateTime(2026, 4, 13),
          note: '',
          description: 'Transferencia temporal',
        ),
      );

      final groupId = created.first.transferGroupId!;
      await datasource.deleteTransactionsByTransferGroup(groupId);

      final rows = await datasource.getTransactions();
      expect(rows.where((item) => item.transferGroupId == groupId), isEmpty);
    });

    test('updateTransfer updates both legs and preserves transfer_group_id',
        () async {
      final created = await datasource.createTransfer(
        AccountTransferEntity(
          fromAccountId: 'acc-main',
          fromAccountName: 'Cuenta principal',
          toAccountId: 'acc-savings',
          toAccountName: 'Ahorros',
          amount: 10000,
          date: DateTime(2026, 4, 10),
          note: 'Inicial',
          description: 'Transferencia inicial',
        ),
      );

      final groupId = created.first.transferGroupId!;

      await datasource.updateTransfer(
        transferGroupId: groupId,
        transfer: AccountTransferEntity(
          fromAccountId: 'acc-savings',
          fromAccountName: 'Ahorros',
          toAccountId: 'acc-main',
          toAccountName: 'Cuenta principal',
          amount: 18000,
          date: DateTime(2026, 4, 14),
          note: 'Editada',
          description: 'Transferencia actualizada',
        ),
      );

      final rows = await datasource.getTransactions();
      final groupRows =
          rows.where((item) => item.transferGroupId == groupId).toList();

      expect(groupRows, hasLength(2));

      final outgoing = groupRows.firstWhere(
        (item) => item.entryType == TransactionEntryType.transferOut,
      );
      final incoming = groupRows.firstWhere(
        (item) => item.entryType == TransactionEntryType.transferIn,
      );

      expect(outgoing.transferGroupId, groupId);
      expect(incoming.transferGroupId, groupId);

      expect(outgoing.accountId, 'acc-savings');
      expect(outgoing.accountName, 'Ahorros');
      expect(outgoing.counterpartyAccountId, 'acc-main');
      expect(outgoing.counterpartyAccountName, 'Cuenta principal');
      expect(outgoing.amount, 18000);
      expect(outgoing.date, DateTime(2026, 4, 14));
      expect(outgoing.note, 'Editada');
      expect(outgoing.description, 'Transferencia actualizada');

      expect(incoming.accountId, 'acc-main');
      expect(incoming.accountName, 'Cuenta principal');
      expect(incoming.counterpartyAccountId, 'acc-savings');
      expect(incoming.counterpartyAccountName, 'Ahorros');
      expect(incoming.amount, 18000);
      expect(incoming.date, DateTime(2026, 4, 14));
      expect(incoming.note, 'Editada');
      expect(incoming.description, 'Transferencia actualizada');
    });

    test('updateTransfer fails when transfer group is incomplete', () async {
      await datasource.insertTransaction(
        TransactionModel(
          id: 'tx-single',
          accountId: 'acc-main',
          accountName: 'Cuenta principal',
          description: 'Transferencia rota',
          categoryId: 'cat-exp-transfer',
          category: 'Transferencia enviada',
          amount: 12000,
          isIncome: false,
          date: DateTime(2026, 4, 12),
          createdAt: DateTime(2026, 4, 12),
          note: '',
          entryType: TransactionEntryType.transferOut,
          transferGroupId: 'broken-group',
          counterpartyAccountId: 'acc-savings',
          counterpartyAccountName: 'Ahorros',
        ),
      );

      expect(
        () => datasource.updateTransfer(
          transferGroupId: 'broken-group',
          transfer: AccountTransferEntity(
            fromAccountId: 'acc-main',
            fromAccountName: 'Cuenta principal',
            toAccountId: 'acc-savings',
            toAccountName: 'Ahorros',
            amount: 15000,
            date: DateTime(2026, 4, 14),
            note: '',
            description: 'No debe actualizar',
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

class _InMemoryTransactionLocalDataSource
    implements TransactionLocalDataSource {
  final List<TransactionModel> _rows = [];

  @override
  Future<List<TransactionModel>> getTransactions() async {
    return List<TransactionModel>.from(_rows);
  }

  @override
  Future<TransactionModel> insertTransaction(
      TransactionModel transaction) async {
    _rows.removeWhere((item) => item.id == transaction.id);
    _rows.add(transaction);
    return transaction;
  }

  @override
  Future<TransactionModel> updateTransaction(
      TransactionModel transaction) async {
    final index = _rows.indexWhere((item) => item.id == transaction.id);
    if (index == -1) {
      throw const FormatException('La transacción no existe.');
    }
    _rows[index] = transaction;
    return transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _rows.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> deleteTransactionsByTransferGroup(String transferGroupId) async {
    _rows.removeWhere((item) => item.transferGroupId == transferGroupId);
  }

  @override
  Future<List<TransactionModel>> createTransfer(
    AccountTransferEntity transfer,
  ) async {
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

    final groupId = 'trf_${_rows.length + 1}';
    final description = transfer.description.trim();
    final note = transfer.note.trim();

    final now = DateTime.now();

    final outgoing = TransactionModel(
      id: '${groupId}_out',
      accountId: transfer.fromAccountId,
      accountName: transfer.fromAccountName,
      description: description.isNotEmpty
          ? description
          : 'Transferencia a ${transfer.toAccountName}',
      categoryId: 'cat-exp-transfer',
      category: 'Transferencia enviada',
      amount: transfer.amount,
      isIncome: false,
      date: transfer.date,
      createdAt: now,
      note: note,
      entryType: TransactionEntryType.transferOut,
      transferGroupId: groupId,
      counterpartyAccountId: transfer.toAccountId,
      counterpartyAccountName: transfer.toAccountName,
    );

    final incoming = TransactionModel(
      id: '${groupId}_in',
      accountId: transfer.toAccountId,
      accountName: transfer.toAccountName,
      description: description.isNotEmpty
          ? description
          : 'Transferencia desde ${transfer.fromAccountName}',
      categoryId: 'cat-inc-transfer',
      category: 'Transferencia recibida',
      amount: transfer.amount,
      isIncome: true,
      date: transfer.date,
      createdAt: now,
      note: note,
      entryType: TransactionEntryType.transferIn,
      transferGroupId: groupId,
      counterpartyAccountId: transfer.fromAccountId,
      counterpartyAccountName: transfer.fromAccountName,
    );

    _rows.addAll([outgoing, incoming]);
    return [outgoing, incoming];
  }

  @override
  Future<void> updateTransfer({
    required String transferGroupId,
    required AccountTransferEntity transfer,
  }) async {
    final groupRows =
        _rows.where((item) => item.transferGroupId == transferGroupId).toList();

    if (groupRows.length != 2) {
      throw const FormatException(
        'No se pudo encontrar la transferencia completa para editar.',
      );
    }

    final outgoingIndex = _rows.indexWhere(
      (item) =>
          item.transferGroupId == transferGroupId &&
          item.entryType == TransactionEntryType.transferOut,
    );
    final incomingIndex = _rows.indexWhere(
      (item) =>
          item.transferGroupId == transferGroupId &&
          item.entryType == TransactionEntryType.transferIn,
    );

    if (outgoingIndex == -1 || incomingIndex == -1) {
      throw const FormatException(
        'La transferencia está incompleta o dañada.',
      );
    }

    final currentOutgoing = _rows[outgoingIndex];
    final currentIncoming = _rows[incomingIndex];
    final description = transfer.description.trim();
    final note = transfer.note.trim();

    _rows[outgoingIndex] = TransactionModel(
      id: currentOutgoing.id,
      accountId: transfer.fromAccountId,
      accountName: transfer.fromAccountName,
      description: description.isNotEmpty
          ? description
          : 'Transferencia a ${transfer.toAccountName}',
      categoryId: 'cat-exp-transfer',
      category: 'Transferencia enviada',
      amount: transfer.amount,
      isIncome: false,
      date: transfer.date,
      createdAt: currentOutgoing.createdAt,
      note: note,
      entryType: TransactionEntryType.transferOut,
      transferGroupId: transferGroupId,
      counterpartyAccountId: transfer.toAccountId,
      counterpartyAccountName: transfer.toAccountName,
    );

    _rows[incomingIndex] = TransactionModel(
      id: currentIncoming.id,
      accountId: transfer.toAccountId,
      accountName: transfer.toAccountName,
      description: description.isNotEmpty
          ? description
          : 'Transferencia desde ${transfer.fromAccountName}',
      categoryId: 'cat-inc-transfer',
      category: 'Transferencia recibida',
      amount: transfer.amount,
      isIncome: true,
      date: transfer.date,
      createdAt: currentIncoming.createdAt,
      note: note,
      entryType: TransactionEntryType.transferIn,
      transferGroupId: transferGroupId,
      counterpartyAccountId: transfer.fromAccountId,
      counterpartyAccountName: transfer.fromAccountName,
    );
  }
}
