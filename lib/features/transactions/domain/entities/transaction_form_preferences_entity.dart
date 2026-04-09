import 'package:equatable/equatable.dart';

class TransactionFormPreferencesEntity extends Equatable {
  const TransactionFormPreferencesEntity({
    this.lastAccountId,
    this.lastExpenseCategoryId,
    this.lastIncomeCategoryId,
    this.lastQuickDateOption,
  });

  final String? lastAccountId;
  final String? lastExpenseCategoryId;
  final String? lastIncomeCategoryId;
  final String? lastQuickDateOption;

  TransactionFormPreferencesEntity copyWith({
    String? lastAccountId,
    String? lastExpenseCategoryId,
    String? lastIncomeCategoryId,
    String? lastQuickDateOption,
  }) {
    return TransactionFormPreferencesEntity(
      lastAccountId: lastAccountId ?? this.lastAccountId,
      lastExpenseCategoryId:
          lastExpenseCategoryId ?? this.lastExpenseCategoryId,
      lastIncomeCategoryId: lastIncomeCategoryId ?? this.lastIncomeCategoryId,
      lastQuickDateOption: lastQuickDateOption ?? this.lastQuickDateOption,
    );
  }

  @override
  List<Object?> get props => [
        lastAccountId,
        lastExpenseCategoryId,
        lastIncomeCategoryId,
        lastQuickDateOption,
      ];
}
