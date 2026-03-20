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
      id: map['id'],
      description: map['description'],
      category: map['category'],
      amount: (map['amount'] as num).toDouble(),
      isIncome: map['isIncome'],
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }
}
