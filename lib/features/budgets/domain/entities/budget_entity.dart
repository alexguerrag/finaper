import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class BudgetEntity extends Equatable {
  const BudgetEntity({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.monthKey,
    required this.amountLimit,
    required this.spentAmount,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String categoryId;
  final String categoryName;
  final String monthKey;
  final double amountLimit;
  final double spentAmount;
  final Color color;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get remainingAmount => amountLimit - spentAmount;

  double get progress {
    if (amountLimit <= 0) return 0;
    final value = spentAmount / amountLimit;
    if (value < 0) return 0;
    return value;
  }

  bool get isExceeded => spentAmount > amountLimit;

  @override
  List<Object?> get props => [
        id,
        categoryId,
        categoryName,
        monthKey,
        amountLimit,
        spentAmount,
        color,
        createdAt,
        updatedAt,
      ];
}
