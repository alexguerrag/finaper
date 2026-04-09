import '../../domain/entities/transaction_form_preferences_entity.dart';

class TransactionFormPreferencesModel extends TransactionFormPreferencesEntity {
  const TransactionFormPreferencesModel({
    super.lastAccountId,
    super.lastExpenseCategoryId,
    super.lastIncomeCategoryId,
    super.lastQuickDateOption,
  });

  factory TransactionFormPreferencesModel.fromMap(Map<String, dynamic> map) {
    return TransactionFormPreferencesModel(
      lastAccountId: map['last_account_id']?.toString(),
      lastExpenseCategoryId: map['last_expense_category_id']?.toString(),
      lastIncomeCategoryId: map['last_income_category_id']?.toString(),
      lastQuickDateOption: map['last_quick_date_option']?.toString(),
    );
  }

  factory TransactionFormPreferencesModel.fromEntity(
    TransactionFormPreferencesEntity entity,
  ) {
    return TransactionFormPreferencesModel(
      lastAccountId: entity.lastAccountId,
      lastExpenseCategoryId: entity.lastExpenseCategoryId,
      lastIncomeCategoryId: entity.lastIncomeCategoryId,
      lastQuickDateOption: entity.lastQuickDateOption,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'last_account_id': lastAccountId,
      'last_expense_category_id': lastExpenseCategoryId,
      'last_income_category_id': lastIncomeCategoryId,
      'last_quick_date_option': lastQuickDateOption,
    };
  }
}
