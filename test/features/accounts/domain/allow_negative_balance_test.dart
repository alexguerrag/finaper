import 'package:finaper/core/enums/account_type.dart';
import 'package:finaper/features/accounts/data/models/account_model.dart';
import 'package:finaper/features/accounts/domain/entities/account_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AccountEntity _account({
  String id = 'acc-1',
  AccountType type = AccountType.bank,
  bool allowNegativeBalance = false,
}) {
  return AccountEntity(
    id: id,
    name: 'Test',
    type: type,
    iconCode: Icons.account_balance_rounded.codePoint,
    color: Colors.blue,
    initialBalance: 0,
    isArchived: false,
    createdAt: DateTime(2024),
    allowNegativeBalance: allowNegativeBalance,
  );
}

List<AccountEntity> _visibleAccounts({
  required List<AccountEntity> accounts,
  required Map<String, double> balances,
  required bool isIncome,
  String? selectedAccountId,
}) {
  if (isIncome) return accounts;
  return accounts.where((account) {
    if (account.id == selectedAccountId) return true;
    final balance = balances[account.id] ?? 0;
    return balance > 0 || account.allowNegativeBalance;
  }).toList();
}

bool _willResultInNegativeBalance({
  required AccountEntity? account,
  required Map<String, double> balances,
  required double amount,
  required bool isIncome,
}) {
  if (isIncome) return false;
  if (account == null || !account.allowNegativeBalance) return false;
  final balance = balances[account.id] ?? 0;
  return balance - amount < 0;
}

void main() {
  group('_visibleAccounts —', () {
    test('1. cuenta con saldo positivo aparece para gasto', () {
      final acc = _account(id: 'a1');
      final result = _visibleAccounts(
        accounts: [acc],
        balances: {'a1': 500},
        isIncome: false,
      );
      expect(result, contains(acc));
    });

    test('2. cuenta con saldo cero y allowNegativeBalance=false no aparece para gasto', () {
      final acc = _account(id: 'a2', allowNegativeBalance: false);
      final result = _visibleAccounts(
        accounts: [acc],
        balances: {'a2': 0},
        isIncome: false,
      );
      expect(result, isEmpty);
    });

    test('3. cuenta con saldo negativo y allowNegativeBalance=false no aparece para gasto', () {
      final acc = _account(id: 'a3', allowNegativeBalance: false);
      final result = _visibleAccounts(
        accounts: [acc],
        balances: {'a3': -100},
        isIncome: false,
      );
      expect(result, isEmpty);
    });

    test('4. cuenta con saldo cero y allowNegativeBalance=true aparece para gasto', () {
      final acc = _account(id: 'a4', allowNegativeBalance: true);
      final result = _visibleAccounts(
        accounts: [acc],
        balances: {'a4': 0},
        isIncome: false,
      );
      expect(result, contains(acc));
    });

    test('5. cuenta con saldo negativo y allowNegativeBalance=true aparece para gasto', () {
      final acc = _account(id: 'a5', allowNegativeBalance: true);
      final result = _visibleAccounts(
        accounts: [acc],
        balances: {'a5': -200},
        isIncome: false,
      );
      expect(result, contains(acc));
    });

    test('6. modo ingreso muestra todas las cuentas activas', () {
      final accounts = [
        _account(id: 'b1', allowNegativeBalance: false),
        _account(id: 'b2', allowNegativeBalance: true),
        _account(id: 'b3'),
      ];
      final result = _visibleAccounts(
        accounts: accounts,
        balances: {'b1': 0, 'b2': -50, 'b3': 100},
        isIncome: true,
      );
      expect(result.length, 3);
    });

    test('7. cuenta seleccionada (edición) permanece visible aunque no cumpla condición', () {
      final acc = _account(id: 'c1', allowNegativeBalance: false);
      final result = _visibleAccounts(
        accounts: [acc],
        balances: {'c1': -500},
        isIncome: false,
        selectedAccountId: 'c1',
      );
      expect(result, contains(acc));
    });
  });

  group('allowNegativeBalance — AccountModel —', () {
    test('8. fromMap con columna ausente retorna false (backward compat)', () {
      final map = {
        'id': 'd1',
        'name': 'Banco',
        'type': 'bank',
        'icon_code': Icons.account_balance_rounded.codePoint,
        'color_value': Colors.blue.toARGB32(),
        'initial_balance': 0.0,
        'is_archived': 0,
        'created_at': '2024-01-01T00:00:00.000',
        // allow_negative_balance ausente
      };
      final model = AccountModel.fromMap(map);
      expect(model.allowNegativeBalance, isFalse);
    });

    test('9. copyWith preserva allowNegativeBalance', () {
      final original = _account(id: 'e1', allowNegativeBalance: true);
      final copy = original.copyWith(name: 'Nuevo nombre');
      expect(copy.allowNegativeBalance, isTrue);
    });

    test('10. tarjeta de crédito nueva tiene allowNegativeBalance=true por defecto', () {
      final creditCard = _account(
        type: AccountType.creditCard,
        allowNegativeBalance: AccountType.creditCard == AccountType.creditCard,
      );
      expect(creditCard.allowNegativeBalance, isTrue);
    });
  });

  group('_willResultInNegativeBalance —', () {
    test('11. aviso aparece cuando balance - monto < 0 y allowNegativeBalance=true', () {
      final acc = _account(id: 'f1', allowNegativeBalance: true);
      final result = _willResultInNegativeBalance(
        account: acc,
        balances: {'f1': 5000},
        amount: 7000,
        isIncome: false,
      );
      expect(result, isTrue);
    });

    test('11b. aviso no aparece cuando allowNegativeBalance=false aunque quede negativo', () {
      final acc = _account(id: 'f2', allowNegativeBalance: false);
      final result = _willResultInNegativeBalance(
        account: acc,
        balances: {'f2': 5000},
        amount: 7000,
        isIncome: false,
      );
      expect(result, isFalse);
    });

    test('11c. aviso no aparece en modo ingreso', () {
      final acc = _account(id: 'f3', allowNegativeBalance: true);
      final result = _willResultInNegativeBalance(
        account: acc,
        balances: {'f3': 0},
        amount: 1000,
        isIncome: true,
      );
      expect(result, isFalse);
    });

    test('11d. aviso aparece cuando cuenta ya está negativa y gasto la deja más negativa', () {
      final acc = _account(id: 'f4', allowNegativeBalance: true);
      final result = _willResultInNegativeBalance(
        account: acc,
        balances: {'f4': -1000},
        amount: 500,
        isIncome: false,
      );
      expect(result, isTrue);
    });
  });
}
