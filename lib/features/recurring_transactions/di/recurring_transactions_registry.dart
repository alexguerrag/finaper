import '../../../app/di/app_locator.dart';

import 'recurring_transactions_module.dart';

class RecurringTransactionsRegistry {
  RecurringTransactionsRegistry._();

  static RecurringTransactionsModule get module =>
      AppLocator.get<RecurringTransactionsModule>();
}
