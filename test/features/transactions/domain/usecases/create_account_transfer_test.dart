import 'package:finaper/features/transactions/domain/entities/account_transfer_entity.dart';
import 'package:finaper/features/transactions/domain/entities/transaction_entity.dart';
import 'package:finaper/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:finaper/features/transactions/domain/usecases/create_account_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateAccountTransfer', () {
    test('delegates transfer creation to repository', () async {
      final repository = _FakeTransactionsRepository();
      final usecase = CreateAccountTransfer(repository);

      final transfer = AccountTransferEntity(
        fromAccountId: 'acc-checking',
        fromAccountName: 'Cuenta corriente',
        toAccountId: 'acc-savings',
        toAccountName: 'Ahorros',
        amount: 25000,
        date: DateTime(2026, 4, 11),
        note: 'Mover saldo',
        description: 'Transferencia a ahorros',
      );

      final result = await usecase(transfer);

      expect(repository.lastTransfer, transfer);
      expect(result, repository.response);
    });
  });
}

class _FakeTransactionsRepository implements TransactionsRepository {
  AccountTransferEntity? lastTransfer;

  final List<TransactionEntity> response = const [];

  @override
  Future<TransactionEntity> add(TransactionEntity transaction) {
    throw UnimplementedError();
  }

  @override
  Future<List<TransactionEntity>> createTransfer(
      AccountTransferEntity transfer) async {
    lastTransfer = transfer;
    return response;
  }

  @override
  Future<void> delete(String id) {
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
}
