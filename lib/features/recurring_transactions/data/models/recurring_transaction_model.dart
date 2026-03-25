import 'package:flutter/material.dart';

import '../../../../core/enums/recurrence_frequency.dart';
import '../../domain/entities/recurring_transaction_entity.dart';

class RecurringTransactionModel extends RecurringTransactionEntity {
  const RecurringTransactionModel({
    required super.id,
    required super.accountId,
    required super.accountName,
    required super.description,
    required super.categoryId,
    required super.categoryName,
    required super.amount,
    required super.isIncome,
    required super.note,
    required super.color,
    required super.frequency,
    required super.intervalValue,
    required super.startDate,
    required super.endDate,
    required super.nextRunDate,
    required super.lastGeneratedDate,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map) {
    return RecurringTransactionModel(
      id: map['id']?.toString() ?? '',
      accountId: map['account_id']?.toString() ?? '',
      accountName: map['account_name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      categoryName: map['category_name']?.toString() ?? '',
      amount: (map['amount'] as num? ?? 0).toDouble(),
      isIncome: (map['is_income'] as int? ?? 0) == 1,
      note: map['note']?.toString() ?? '',
      color: map['color_value'] != null
          ? Color(map['color_value'] as int).withValues(alpha: 1.0)
          : Colors.blue.withValues(alpha: 1.0),
      frequency: RecurrenceFrequencyX.fromValue(
        map['frequency']?.toString(),
      ),
      intervalValue: map['interval_value'] as int? ?? 1,
      startDate: DateTime.tryParse(map['start_date']?.toString() ?? '') ??
          DateTime.now(),
      endDate: map['end_date'] != null && map['end_date'].toString().isNotEmpty
          ? DateTime.tryParse(map['end_date'].toString())
          : null,
      nextRunDate: DateTime.tryParse(map['next_run_date']?.toString() ?? '') ??
          DateTime.now(),
      lastGeneratedDate: map['last_generated_date'] != null &&
              map['last_generated_date'].toString().isNotEmpty
          ? DateTime.tryParse(map['last_generated_date'].toString())
          : null,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory RecurringTransactionModel.fromEntity(
    RecurringTransactionEntity entity,
  ) {
    return RecurringTransactionModel(
      id: entity.id,
      accountId: entity.accountId,
      accountName: entity.accountName,
      description: entity.description,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      amount: entity.amount,
      isIncome: entity.isIncome,
      note: entity.note,
      color: entity.color.withValues(alpha: 1.0),
      frequency: entity.frequency,
      intervalValue: entity.intervalValue,
      startDate: entity.startDate,
      endDate: entity.endDate,
      nextRunDate: entity.nextRunDate,
      lastGeneratedDate: entity.lastGeneratedDate,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'account_name': accountName,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'amount': amount,
      'is_income': isIncome ? 1 : 0,
      'note': note,
      'color_value': color.toARGB32(),
      'frequency': frequency.value,
      'interval_value': intervalValue,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'next_run_date': nextRunDate.toIso8601String(),
      'last_generated_date': lastGeneratedDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
