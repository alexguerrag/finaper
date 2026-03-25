import 'dart:math';

import '../../../../core/enums/recurrence_frequency.dart';

DateTime calculateNextOccurrence(
  DateTime date,
  RecurrenceFrequency frequency,
  int intervalValue,
) {
  final safeInterval = intervalValue <= 0 ? 1 : intervalValue;

  switch (frequency) {
    case RecurrenceFrequency.daily:
      return date.add(Duration(days: safeInterval));
    case RecurrenceFrequency.weekly:
      return date.add(Duration(days: 7 * safeInterval));
    case RecurrenceFrequency.monthly:
      return _addMonthsClamped(date, safeInterval);
    case RecurrenceFrequency.yearly:
      return _addYearsClamped(date, safeInterval);
  }
}

DateTime _addMonthsClamped(DateTime date, int monthsToAdd) {
  final totalMonths = (date.year * 12) + (date.month - 1) + monthsToAdd;
  final year = totalMonths ~/ 12;
  final month = (totalMonths % 12) + 1;
  final maxDay = _daysInMonth(year, month);
  final day = min(date.day, maxDay);

  return DateTime(
    year,
    month,
    day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}

DateTime _addYearsClamped(DateTime date, int yearsToAdd) {
  final year = date.year + yearsToAdd;
  final month = date.month;
  final maxDay = _daysInMonth(year, month);
  final day = min(date.day, maxDay);

  return DateTime(
    year,
    month,
    day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}

int _daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}
