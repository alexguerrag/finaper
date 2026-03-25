import 'package:flutter_test/flutter_test.dart';
import 'package:finaper/core/enums/recurrence_frequency.dart';
import 'package:finaper/features/recurring_transactions/domain/utils/recurrence_date_utils.dart';

void main() {
  test('monthly recurrence mantiene el ultimo dia valido del mes', () {
    final result = calculateNextOccurrence(
      DateTime(2026, 1, 31),
      RecurrenceFrequency.monthly,
      1,
    );

    expect(result.year, 2026);
    expect(result.month, 2);
    expect(result.day, 28);
  });

  test('weekly recurrence suma 7 dias por intervalo', () {
    final result = calculateNextOccurrence(
      DateTime(2026, 3, 1),
      RecurrenceFrequency.weekly,
      2,
    );

    expect(result, DateTime(2026, 3, 15));
  });
}
