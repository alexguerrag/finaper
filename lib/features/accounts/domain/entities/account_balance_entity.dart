import 'package:equatable/equatable.dart';

import 'account_entity.dart';

class AccountBalanceEntity extends Equatable {
  const AccountBalanceEntity({
    required this.account,
    required this.totalIncome,
    required this.totalExpense,
  });

  final AccountEntity account;
  final double totalIncome;
  final double totalExpense;

  double get initialBalance => account.initialBalance;

  double get netFlow => totalIncome - totalExpense;

  double get currentBalance => initialBalance + netFlow;

  @override
  List<Object?> get props => [
        account,
        totalIncome,
        totalExpense,
      ];
}
