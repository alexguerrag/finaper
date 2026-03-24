import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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
    required this.note,
    this.color,
  });

  final String? id;
  final String accountId;
  final String accountName;
  final String description;
  final String categoryId;
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String note;
  final Color? color;

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
        note,
        color,
      ];
}
