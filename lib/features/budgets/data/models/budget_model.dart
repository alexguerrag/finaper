import 'package:flutter/material.dart';

import '../../domain/entities/budget_entity.dart';

class BudgetModel extends BudgetEntity {
  const BudgetModel({
    required super.id,
    required super.categoryId,
    required super.categoryName,
    required super.monthKey,
    required super.amountLimit,
    required super.spentAmount,
    required super.color,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BudgetModel.fromMap(
    Map<String, dynamic> map, {
    double spentAmount = 0,
  }) {
    return BudgetModel(
      id: map['id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      categoryName: map['category_name']?.toString() ?? '',
      monthKey: map['month_key']?.toString() ?? '',
      amountLimit: (map['amount_limit'] as num? ?? 0).toDouble(),
      spentAmount: spentAmount,
      color: map['color_value'] != null
          ? Color(map['color_value'] as int).withValues(alpha: 1.0)
          : Colors.grey.withValues(alpha: 1.0),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory BudgetModel.fromEntity(BudgetEntity entity) {
    return BudgetModel(
      id: entity.id,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      monthKey: entity.monthKey,
      amountLimit: entity.amountLimit,
      spentAmount: entity.spentAmount,
      color: entity.color.withValues(alpha: 1.0),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'category_name': categoryName,
      'month_key': monthKey,
      'amount_limit': amountLimit,
      'color_value': color.toARGB32(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
