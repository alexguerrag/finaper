class SavingsRateEntity {
  const SavingsRateEntity({
    required this.rate,
    required this.income,
    required this.expense,
    required this.savedAmount,
    this.previousRate,
  });

  /// (income − expense) / income × 100. Can be negative.
  final double rate;
  final double income;
  final double expense;
  final double savedAmount;

  /// null when no previous-month transactions exist.
  final double? previousRate;

  double? get rateDelta =>
      previousRate != null ? rate - previousRate! : null;
}
