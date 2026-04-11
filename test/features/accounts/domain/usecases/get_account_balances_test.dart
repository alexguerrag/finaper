import 'package:finaper/core/enums/account_type.dart';
import 'package:finaper/features/accounts/domain/entities/account_balance_entity.dart';
import 'package:finaper/features/accounts/domain/entities/account_entity.dart';
import 'package:finaper/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:finaper/features/accounts/domain/usecases/get_account_balances.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GetAccountBalances devuelve los balances entregados por el repositorio',
      () async {
    final repository = _FakeAccountsRepository(
      balances: [
        AccountBalanceEntity(
          account: AccountEntity(
            id: 'acc-1',
            name: 'Banco principal',
            type: AccountType.bank,
            iconCode: Icons.account_balance_rounded.codePoint,
            color: Colors.indigo.withValues(alpha: 1.0),
            initialBalance: 100,
            isArchived: false,
            createdAt: DateTime(2026, 4, 10),
          ),
          totalIncome: 50,
          totalExpense: 20,
        ),
      ],
    );

    final usecase = GetAccountBalances(repository);

    final result = await usecase();

    expect(result, hasLength(1));
    expect(result.first.account.name, 'Banco principal');
    expect(result.first.initialBalance, 100);
    expect(result.first.netFlow, 30);
    expect(result.first.currentBalance, 130);
  });
}

class _FakeAccountsRepository implements AccountsRepository {
  _FakeAccountsRepository({
    required this.balances,
  });

  final List<AccountBalanceEntity> balances;

  @override
  Future<AccountEntity> createAccount(AccountEntity account) async {
    return account;
  }

  @override
  Future<List<AccountBalanceEntity>> getAccountBalances({
    bool includeArchived = false,
  }) async {
    return balances;
  }

  @override
  Future<List<AccountEntity>> getAccounts({
    bool includeArchived = false,
  }) async {
    return balances.map((item) => item.account).toList();
  }

  @override
  Future<AccountEntity> updateAccount(AccountEntity account) async {
    return account;
  }
}
