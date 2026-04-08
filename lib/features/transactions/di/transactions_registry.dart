import '../../../app/di/app_locator.dart';

import 'transactions_module.dart';

class TransactionsRegistry {
  TransactionsRegistry._();

  static TransactionsModule get module => AppLocator.get<TransactionsModule>();
}
