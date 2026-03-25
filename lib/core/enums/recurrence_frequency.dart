enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

extension RecurrenceFrequencyX on RecurrenceFrequency {
  String get value {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'daily';
      case RecurrenceFrequency.weekly:
        return 'weekly';
      case RecurrenceFrequency.monthly:
        return 'monthly';
      case RecurrenceFrequency.yearly:
        return 'yearly';
    }
  }

  String get label {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Diaria';
      case RecurrenceFrequency.weekly:
        return 'Semanal';
      case RecurrenceFrequency.monthly:
        return 'Mensual';
      case RecurrenceFrequency.yearly:
        return 'Anual';
    }
  }

  static RecurrenceFrequency fromValue(String? value) {
    switch (value) {
      case 'weekly':
        return RecurrenceFrequency.weekly;
      case 'monthly':
        return RecurrenceFrequency.monthly;
      case 'yearly':
        return RecurrenceFrequency.yearly;
      case 'daily':
      default:
        return RecurrenceFrequency.daily;
    }
  }
}
