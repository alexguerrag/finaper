import 'package:flutter/material.dart';

import '../../../../core/enums/account_type.dart';
import '../../domain/entities/account_entity.dart';

class AccountModel extends AccountEntity {
  const AccountModel({
    required super.id,
    required super.name,
    required super.type,
    required super.iconCode,
    required super.color,
    required super.isArchived,
    required super.createdAt,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: AccountTypeX.fromValue(map['type']?.toString()),
      iconCode: map['icon_code'] as int? ??
          Icons.account_balance_wallet_rounded.codePoint,
      color: map['color_value'] != null
          ? Color(map['color_value'] as int).withValues(alpha: 1.0)
          : Colors.blue.withValues(alpha: 1.0),
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory AccountModel.fromEntity(AccountEntity entity) {
    return AccountModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      iconCode: entity.iconCode,
      color: entity.color.withValues(alpha: 1.0),
      isArchived: entity.isArchived,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'icon_code': iconCode,
      'color_value': color.toARGB32(),
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
