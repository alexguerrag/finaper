import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'transaction_entry_type.dart';

class TransactionEntity extends Equatable {
  const TransactionEntity({
    this.id,
    this.accountId = 'acc-cash-main',
    this.accountName = 'Cuenta principal',
    required this.description,
    this.categoryId = 'cat-exp-other',
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.createdAt,
    required this.note,
    this.color,
    this.entryType = TransactionEntryType.standard,
    this.transferGroupId,
    this.counterpartyAccountId,
    this.counterpartyAccountName,
  });

  final String? id;
  final String accountId;
  final String accountName;
  final String description;
  final String categoryId;
  final String category;
  final double amount;
  final bool isIncome;

  /// Fecha financiera del movimiento (solo fecha, sin hora).
  final DateTime date;

  /// Momento real de creación del registro. Usado como desempate en ordenamiento.
  final DateTime createdAt;
  final String note;
  final Color? color;

  final TransactionEntryType entryType;
  final String? transferGroupId;
  final String? counterpartyAccountId;
  final String? counterpartyAccountName;

  bool get isTransfer => entryType.isTransfer;

  @override
  List<Object?> get props => [
        id,
        accountId,
        accountName,
        description,
        categoryId,
        category,
        amount,
        isIncome,
        date,
        createdAt,
        note,
        color,
        entryType,
        transferGroupId,
        counterpartyAccountId,
        counterpartyAccountName,
      ];
}
