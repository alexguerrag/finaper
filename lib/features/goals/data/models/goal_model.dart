import 'package:flutter/material.dart';

import '../../domain/entities/goal_entity.dart';

class GoalModel extends GoalEntity {
  const GoalModel({
    required super.id,
    required super.name,
    required super.targetAmount,
    required super.currentAmount,
    required super.targetDate,
    required super.color,
    required super.iconCode,
    required super.isCompleted,
    required super.createdAt,
    required super.updatedAt,
  });

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      targetAmount: (map['target_amount'] as num? ?? 0).toDouble(),
      currentAmount: (map['current_amount'] as num? ?? 0).toDouble(),
      targetDate:
          map['target_date'] != null && map['target_date'].toString().isNotEmpty
              ? DateTime.tryParse(map['target_date'].toString())
              : null,
      color: map['color_value'] != null
          ? Color(map['color_value'] as int).withValues(alpha: 1.0)
          : Colors.blue.withValues(alpha: 1.0),
      iconCode: map['icon_code'] as int? ?? Icons.flag_rounded.codePoint,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory GoalModel.fromEntity(GoalEntity entity) {
    return GoalModel(
      id: entity.id,
      name: entity.name,
      targetAmount: entity.targetAmount,
      currentAmount: entity.currentAmount,
      targetDate: entity.targetDate,
      color: entity.color.withValues(alpha: 1.0),
      iconCode: entity.iconCode,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toIso8601String(),
      'color_value': color.toARGB32(),
      'icon_code': iconCode,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
