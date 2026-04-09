import '../entities/transaction_form_preferences_entity.dart';
import '../repositories/transaction_form_preferences_repository.dart';

class GetTransactionFormPreferences {
  const GetTransactionFormPreferences(this._repository);

  final TransactionFormPreferencesRepository _repository;

  Future<TransactionFormPreferencesEntity> call() {
    return _repository.getPreferences();
  }
}
