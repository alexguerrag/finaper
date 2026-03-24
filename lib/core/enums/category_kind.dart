enum CategoryKind {
  expense,
  income,
}

extension CategoryKindX on CategoryKind {
  String get value {
    switch (this) {
      case CategoryKind.expense:
        return 'expense';
      case CategoryKind.income:
        return 'income';
    }
  }

  String get label {
    switch (this) {
      case CategoryKind.expense:
        return 'Gasto';
      case CategoryKind.income:
        return 'Ingreso';
    }
  }

  static CategoryKind fromValue(String? value) {
    switch (value) {
      case 'income':
        return CategoryKind.income;
      case 'expense':
      default:
        return CategoryKind.expense;
    }
  }
}
