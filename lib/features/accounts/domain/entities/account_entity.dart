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
    this.allowNegativeBalance = false,
  });

  final String id;
  final String name;
  final AccountType type;
  final int iconCode;
  final Color color;
  final double initialBalance;
  final bool isArchived;
  final DateTime createdAt;

  /// Permite que la cuenta opere con saldo negativo (línea de crédito,
  /// sobregiro o tarjeta de crédito). Por defecto false.
  final bool allowNegativeBalance;

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
        allowNegativeBalance,
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
    bool? allowNegativeBalance,
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
      allowNegativeBalance: allowNegativeBalance ?? this.allowNegativeBalance,
    );
  }
}
