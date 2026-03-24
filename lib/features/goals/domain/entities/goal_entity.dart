import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class GoalEntity extends Equatable {
  const GoalEntity({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.color,
    required this.iconCode,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final Color color;
  final int iconCode;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get remainingAmount {
    final value = targetAmount - currentAmount;
    return value < 0 ? 0 : value;
  }

  double get progress {
    if (targetAmount <= 0) return 0;
    final value = currentAmount / targetAmount;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        targetAmount,
        currentAmount,
        targetDate,
        color,
        iconCode,
        isCompleted,
        createdAt,
        updatedAt,
      ];
}
