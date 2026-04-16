import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../core/enums/category_kind.dart';

class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconCode,
    required this.color,
    required this.isSystem,
    required this.isArchived,
    required this.createdAt,
  });

  final String id;
  final String name;
  final CategoryKind kind;
  final int iconCode;
  final Color color;
  final bool isSystem;
  final bool isArchived;
  final DateTime createdAt;

  CategoryEntity copyWith({
    String? id,
    String? name,
    CategoryKind? kind,
    int? iconCode,
    Color? color,
    bool? isSystem,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      iconCode: iconCode ?? this.iconCode,
      color: color ?? this.color,
      isSystem: isSystem ?? this.isSystem,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        kind,
        iconCode,
        color,
        isSystem,
        isArchived,
        createdAt,
      ];
}
