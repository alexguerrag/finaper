import 'package:finaper/core/enums/account_type.dart';
import 'package:finaper/features/accounts/data/local/accounts_local_datasource.dart';
import 'package:finaper/features/accounts/data/models/account_model.dart';
import 'package:finaper/features/accounts/domain/entities/account_balance_entity.dart';
import 'package:finaper/features/accounts/domain/entities/account_entity.dart';
import 'package:finaper/features/dashboard/data/local/dashboard_local_datasource.dart';
import 'package:finaper/features/transactions/data/local/transaction_local_datasource.dart';
import 'package:finaper/features/transactions/data/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardLocalDataSource', () {
    late _FakeTransactionLocalDataSource transactionLocalDataSource;
    late _FakeAccountsLocalDataSource accountsLocalDataSource;
    late DashboardLocalDataSource dashboardLocalDataSource;

    setUp(() {
      transactionLocalDataSource = _FakeTransactionLocalDataSource();
      accountsLocalDataSource = _FakeAccountsLocalDataSource();
      dashboardLocalDataSource = DashboardLocalDataSource(
        transactionLocalDataSource,
        accountsLocalDataSource,
      );
    });

    test('usa saldo consolidado real derivado desde cuentas', () async {
      accountsLocalDataSource.balances = [
        AccountBalanceEntity(
          account: AccountEntity(
            id: 'acc-1',
            name: 'Banco',
            type: AccountType.bank,
            iconCode: Icons.account_balance_rounded.codePoint,
            color: Colors.indigo.withValues(alpha: 1.0),
            initialBalance: 1000,
            isArchived: false,
            createdAt: DateTime(2026, 4, 1),
          ),
          totalIncome: 200,
          totalExpense: 50,
        ),
        AccountBalanceEntity(
          account: AccountEntity(
            id: 'acc-2',
            name: 'Efectivo',
            type: AccountType.cash,
            iconCode: Icons.account_balance_wallet_rounded.codePoint,
            color: Colors.blue.withValues(alpha: 1.0),
            initialBalance: 300,
            isArchived: false,
            createdAt: DateTime(2026, 4, 1),
          ),
          totalIncome: 0,
          totalExpense: 20,
        ),
      ];

      final summary = await dashboardLocalDataSource.getSummary(
        month: DateTime(2026, 4, 1),
      );

      expect(summary.consolidatedBalance, 1430);
    });

    test(
      'calcula ingresos, gastos, neto y movimientos solo del mes seleccionado',
      () async {
        transactionLocalDataSource.transactions = [
          _expenseTransaction(
            id: 'tx-1',
            amount: 10,
            categoryId: 'food',
            category: 'Alimentación',
            date: DateTime(2026, 4, 10),
          ),
          _incomeTransaction(
            id: 'tx-2',
            amount: 130,
            categoryId: 'salary',
            category: 'Salario',
            date: DateTime(2026, 4, 8),
          ),
          _incomeTransaction(
            id: 'tx-3',
            amount: 100,
            categoryId: 'freelance',
            category: 'Freelance',
            date: DateTime(2026, 4, 2),
          ),
          _expenseTransaction(
            id: 'tx-4',
            amount: 70,
            categoryId: 'transport',
            category: 'Transporte',
            date: DateTime(2026, 3, 25),
          ),
        ];

        final summary = await dashboardLocalDataSource.getSummary(
          month: DateTime(2026, 4, 1),
        );

        expect(summary.monthIncome, 230);
        expect(summary.monthExpense, 10);
        expect(summary.monthNetFlow, 220);

        expect(summary.recentTransactions, hasLength(3));
        expect(
          summary.recentTransactions.every(
            (transaction) =>
                transaction.date.year == 2026 && transaction.date.month == 4,
          ),
          isTrue,
        );
      },
    );

    test(
      'ordena categorias de gasto por monto y calcula porcentajes del mes',
      () async {
        transactionLocalDataSource.transactions = [
          _expenseTransaction(
            id: 'tx-1',
            amount: 60,
            categoryId: 'food',
            category: 'Alimentación',
            date: DateTime(2026, 4, 11),
            color: const Color(0xFFFF9800),
          ),
          _expenseTransaction(
            id: 'tx-2',
            amount: 40,
            categoryId: 'transport',
            category: 'Transporte',
            date: DateTime(2026, 4, 9),
            color: const Color(0xFF2196F3),
          ),
          _expenseTransaction(
            id: 'tx-3',
            amount: 20,
            categoryId: 'food',
            category: 'Alimentación',
            date: DateTime(2026, 4, 5),
            color: const Color(0xFFFF9800),
          ),
          _incomeTransaction(
            id: 'tx-4',
            amount: 200,
            categoryId: 'salary',
            category: 'Salario',
            date: DateTime(2026, 4, 1),
          ),
        ];

        final summary = await dashboardLocalDataSource.getSummary(
          month: DateTime(2026, 4, 1),
        );

        expect(summary.topExpenseCategories, hasLength(2));

        final firstCategory = summary.topExpenseCategories.first;
        final secondCategory = summary.topExpenseCategories.last;

        expect(firstCategory.categoryId, 'food');
        expect(firstCategory.categoryName, 'Alimentación');
        expect(firstCategory.amount, 80);
        expect(firstCategory.percentage, closeTo(0.6667, 0.001));

        expect(secondCategory.categoryId, 'transport');
        expect(secondCategory.amount, 40);
        expect(secondCategory.percentage, closeTo(0.3333, 0.001));
      },
    );
  });
}

class _FakeTransactionLocalDataSource implements TransactionLocalDataSource {
  List<TransactionModel> transactions = [];

  @override
  Future<List<TransactionModel>> getTransactions() async {
    return transactions;
  }

  @override
  Future<TransactionModel> insertTransaction(TransactionModel transaction) {
    throw UnimplementedError();
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel transaction) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTransaction(String id) {
    throw UnimplementedError();
  }
}

class _FakeAccountsLocalDataSource implements AccountsLocalDataSource {
  List<AccountBalanceEntity> balances = [];

  @override
  Future<AccountModel> createAccount(AccountModel account) {
    throw UnimplementedError();
  }

  @override
  Future<List<AccountModel>> getAccounts({
    bool includeArchived = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<AccountBalanceEntity>> getAccountBalances({
    bool includeArchived = false,
  }) async {
    return balances;
  }

  @override
  Future<AccountModel> updateAccount(AccountModel account) {
    throw UnimplementedError();
  }
}

TransactionModel _incomeTransaction({
  required String id,
  required double amount,
  required String categoryId,
  required String category,
  required DateTime date,
  Color? color,
}) {
  return TransactionModel(
    id: id,
    description: 'Ingreso $id',
    accountId: 'acc-main',
    accountName: 'Cuenta principal',
    categoryId: categoryId,
    category: category,
    amount: amount,
    isIncome: true,
    date: date,
    note: '',
    color: color ?? Colors.green.withValues(alpha: 1.0),
  );
}

TransactionModel _expenseTransaction({
  required String id,
  required double amount,
  required String categoryId,
  required String category,
  required DateTime date,
  Color? color,
}) {
  return TransactionModel(
    id: id,
    description: 'Gasto $id',
    accountId: 'acc-main',
    accountName: 'Cuenta principal',
    categoryId: categoryId,
    category: category,
    amount: amount,
    isIncome: false,
    date: date,
    note: '',
    color: color ?? Colors.red.withValues(alpha: 1.0),
  );
}
