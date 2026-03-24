import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../core/enums/account_type.dart';

class AccountEntity extends Equatable {
  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCode,
    required this.color,
    required this.isArchived,
    required this.createdAt,
  });

  final String id;
  final String name;
  final AccountType type;
  final int iconCode;
  final Color color;
  final bool isArchived;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        iconCode,
        color,
        isArchived,
        createdAt,
      ];
}
