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
    required this.createdAt,
  });

  final String id;
  final String name;
  final CategoryKind kind;
  final int iconCode;
  final Color color;
  final bool isSystem;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        name,
        kind,
        iconCode,
        color,
        isSystem,
        createdAt,
      ];
}
