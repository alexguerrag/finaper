import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    super.id,
    required super.description,
    required super.category,
    required super.amount,
    required super.isIncome,
    required super.date,
    required super.note,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      description: map['description'],
      category: map['category'],
      amount: map['amount'],
      isIncome: map['is_income'] == 1,
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'category': category,
      'amount': amount,
      'is_income': isIncome ? 1 : 0,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      description: entity.description,
      category: entity.category,
      amount: entity.amount,
      isIncome: entity.isIncome,
      date: entity.date,
      note: entity.note,
    );
  }
}
