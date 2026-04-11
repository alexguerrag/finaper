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
    required this.initialBalance,
    required this.isArchived,
    required this.createdAt,
  });

  final String id;
  final String name;
  final AccountType type;
  final int iconCode;
  final Color color;
  final double initialBalance;
  final bool isArchived;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        iconCode,
        color,
        initialBalance,
        isArchived,
        createdAt,
      ];

  AccountEntity copyWith({
    String? id,
    String? name,
    AccountType? type,
    int? iconCode,
    Color? color,
    double? initialBalance,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconCode: iconCode ?? this.iconCode,
      color: color ?? this.color,
      initialBalance: initialBalance ?? this.initialBalance,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
