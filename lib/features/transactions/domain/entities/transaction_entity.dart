import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class TransactionEntity extends Equatable {
  final String? id;
  final String description;
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String note;
  final Color? color;

  const TransactionEntity({
    this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.note,
    this.color,
  });

  @override
  List<Object?> get props => [
        id,
        description,
        category,
        amount,
        isIncome,
        date,
        note,
        color,
      ];
}
