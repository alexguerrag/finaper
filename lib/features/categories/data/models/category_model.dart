import 'package:flutter/material.dart';

import '../../../../core/enums/category_kind.dart';
import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.kind,
    required super.iconCode,
    required super.color,
    required super.isSystem,
    required super.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      kind: CategoryKindX.fromValue(map['kind']?.toString()),
      iconCode: map['icon_code'] as int? ?? Icons.more_horiz_rounded.codePoint,
      color: map['color_value'] != null
          ? Color(map['color_value'] as int).withValues(alpha: 1.0)
          : Colors.grey.withValues(alpha: 1.0),
      isSystem: (map['is_system'] as int? ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      kind: entity.kind,
      iconCode: entity.iconCode,
      color: entity.color.withValues(alpha: 1.0),
      isSystem: entity.isSystem,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'kind': kind.value,
      'icon_code': iconCode,
      'color_value': color.toARGB32(),
      'is_system': isSystem ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
