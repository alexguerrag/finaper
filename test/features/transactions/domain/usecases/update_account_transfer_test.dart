import 'package:finaper/features/transactions/domain/entities/account_transfer_entity.dart';
import 'package:finaper/features/transactions/domain/entities/transaction_entity.dart';
import 'package:finaper/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:finaper/features/transactions/domain/usecases/update_account_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateAccountTransfer', () {
    test('delegates grouped transfer update to repository', () async {
      final repository = _FakeTransactionsRepository();
      final usecase = UpdateAccountTransfer(repository);

      final transfer = AccountTransferEntity(
        fromAccountId: 'acc-checking',
        fromAccountName: 'Cuenta corriente',
        toAccountId: 'acc-savings',
        toAccountName: 'Ahorros',
        amount: 45000,
        date: DateTime(2026, 4, 13),
        note: 'Mover saldo actualizado',
        description: 'Transferencia editada',
      );

      await usecase(
        transferGroupId: 'grp-123',
        transfer: transfer,
      );

      expect(repository.lastTransferGroupId, 'grp-123');
      expect(repository.lastUpdatedTransfer, transfer);
    });
  });
}

class _FakeTransactionsRepository implements TransactionsRepository {
  String? lastTransferGroupId;
  AccountTransferEntity? lastUpdatedTransfer;

  @override
  Future<TransactionEntity> add(TransactionEntity transaction) {
    throw UnimplementedError();
  }

  @override
  Future<List<TransactionEntity>> createTransfer(
    AccountTransferEntity transfer,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteByTransferGroup(String transferGroupId) {
    throw UnimplementedError();
  }

  @override
  Future<List<TransactionEntity>> getAll() {
    throw UnimplementedError();
  }

  @override
  Future<TransactionEntity> update(TransactionEntity transaction) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateTransfer({
    required String transferGroupId,
    required AccountTransferEntity transfer,
  }) async {
    lastTransferGroupId = transferGroupId;
    lastUpdatedTransfer = transfer;
  }
}
