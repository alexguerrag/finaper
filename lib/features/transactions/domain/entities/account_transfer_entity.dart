import 'package:equatable/equatable.dart';

class AccountTransferEntity extends Equatable {
  const AccountTransferEntity({
    required this.fromAccountId,
    required this.fromAccountName,
    required this.toAccountId,
    required this.toAccountName,
    required this.amount,
    required this.date,
    required this.note,
    required this.description,
  });

  final String fromAccountId;
  final String fromAccountName;
  final String toAccountId;
  final String toAccountName;
  final double amount;
  final DateTime date;
  final String note;
  final String description;

  @override
  List<Object?> get props => [
        fromAccountId,
        fromAccountName,
        toAccountId,
        toAccountName,
        amount,
        date,
        note,
        description,
      ];
}
