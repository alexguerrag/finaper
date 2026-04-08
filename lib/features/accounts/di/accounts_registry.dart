import '../../../app/di/app_locator.dart';

import 'accounts_module.dart';

class AccountsRegistry {
  AccountsRegistry._();

  static AccountsModule get module => AppLocator.get<AccountsModule>();
}
