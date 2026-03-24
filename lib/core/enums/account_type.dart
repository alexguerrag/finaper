enum AccountType {
  cash,
  bank,
  savings,
  creditCard,
  investment,
}

extension AccountTypeX on AccountType {
  String get value {
    switch (this) {
      case AccountType.cash:
        return 'cash';
      case AccountType.bank:
        return 'bank';
      case AccountType.savings:
        return 'savings';
      case AccountType.creditCard:
        return 'credit_card';
      case AccountType.investment:
        return 'investment';
    }
  }

  String get label {
    switch (this) {
      case AccountType.cash:
        return 'Efectivo';
      case AccountType.bank:
        return 'Banco';
      case AccountType.savings:
        return 'Ahorros';
      case AccountType.creditCard:
        return 'Tarjeta';
      case AccountType.investment:
        return 'Inversión';
    }
  }

  static AccountType fromValue(String? value) {
    switch (value) {
      case 'bank':
        return AccountType.bank;
      case 'savings':
        return AccountType.savings;
      case 'credit_card':
        return AccountType.creditCard;
      case 'investment':
        return AccountType.investment;
      case 'cash':
      default:
        return AccountType.cash;
    }
  }
}
