class TransactionEntity {
  final int? id;
  final String description;
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String note;

  const TransactionEntity({
    this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.note,
  });
}
