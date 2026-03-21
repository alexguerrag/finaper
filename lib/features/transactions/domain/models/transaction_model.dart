class TransactionModel {
  final String id;
  final String description;
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String note;

  const TransactionModel({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.note,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      isIncome: (map['isIncome'] as int) == 1 || map['isIncome'] == true,
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'category': category,
      'amount': amount,
      'isIncome': isIncome ? 1 : 0,
      'date': date.toIso8601String(),
      'note': note,
    };
  }
}
