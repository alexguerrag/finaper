import 'package:flutter/material.dart';

import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_entry_type.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    super.id,
    super.accountId = 'acc-cash-main',
    super.accountName = 'Cuenta principal',
    required super.description,
    super.categoryId = 'cat-exp-other',
    required super.category,
    required super.amount,
    required super.isIncome,
    required super.date,
    required super.createdAt,
    required super.note,
    super.color,
    super.entryType = TransactionEntryType.standard,
    super.transferGroupId,
    super.counterpartyAccountId,
    super.counterpartyAccountName,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final isIncome = (map['is_income'] as int? ?? 0) == 1;
    final date =
        DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now();

    // Backfill seguro: si created_at no existe (filas previas a v11), usa date.
    final createdAt =
        DateTime.tryParse(map['created_at']?.toString() ?? '') ?? date;

    return TransactionModel(
      id: map['id']?.toString(),
      accountId: map['account_id']?.toString() ?? 'acc-cash-main',
      accountName: map['account_name']?.toString() ?? 'Cuenta principal',
      description: map['description']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ??
          (isIncome ? 'cat-inc-other' : 'cat-exp-other'),
      category: map['category']?.toString() ?? 'Otros',
      amount: (map['amount'] as num? ?? 0).toDouble(),
      isIncome: isIncome,
      date: date,
      createdAt: createdAt,
      note: map['note']?.toString() ?? '',
      color: map['color_value'] != null
          ? Color(map['color_value'] as int).withValues(alpha: 1.0)
          : (isIncome
              ? Colors.green.withValues(alpha: 1.0)
              : Colors.red.withValues(alpha: 1.0)),
      entryType: TransactionEntryType.fromStorage(
        map['entry_type']?.toString(),
      ),
      transferGroupId: map['transfer_group_id']?.toString(),
      counterpartyAccountId: map['counterparty_account_id']?.toString(),
      counterpartyAccountName: map['counterparty_account_name']?.toString(),
    );
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      accountId: entity.accountId,
      accountName: entity.accountName,
      description: entity.description,
      categoryId: entity.categoryId,
      category: entity.category,
      amount: entity.amount,
      isIncome: entity.isIncome,
      date: entity.date,
      createdAt: entity.createdAt,
      note: entity.note,
      color: entity.color?.withValues(alpha: 1.0),
      entryType: entity.entryType,
      transferGroupId: entity.transferGroupId,
      counterpartyAccountId: entity.counterpartyAccountId,
      counterpartyAccountName: entity.counterpartyAccountName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'account_name': accountName,
      'description': description,
      'category_id': categoryId,
      'category': category,
      'amount': amount,
      'is_income': isIncome ? 1 : 0,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'note': note,
      'color_value': color?.toARGB32() ??
          (isIncome ? Colors.green.toARGB32() : Colors.red.toARGB32()),
      'entry_type': entryType.storageValue,
      'transfer_group_id': transferGroupId,
      'counterparty_account_id': counterpartyAccountId,
      'counterparty_account_name': counterpartyAccountName,
    };
  }
}
