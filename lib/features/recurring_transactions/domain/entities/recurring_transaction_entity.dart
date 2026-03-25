import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../core/enums/recurrence_frequency.dart';

class RecurringTransactionEntity extends Equatable {
  const RecurringTransactionEntity({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.isIncome,
    required this.note,
    required this.color,
    required this.frequency,
    required this.intervalValue,
    required this.startDate,
    required this.endDate,
    required this.nextRunDate,
    required this.lastGeneratedDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String accountId;
  final String accountName;
  final String description;
  final String categoryId;
  final String categoryName;
  final double amount;
  final bool isIncome;
  final String note;
  final Color color;
  final RecurrenceFrequency frequency;
  final int intervalValue;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextRunDate;
  final DateTime? lastGeneratedDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        accountId,
        accountName,
        description,
        categoryId,
        categoryName,
        amount,
        isIncome,
        note,
        color,
        frequency,
        intervalValue,
        startDate,
        endDate,
        nextRunDate,
        lastGeneratedDate,
        isActive,
        createdAt,
        updatedAt,
      ];
}
