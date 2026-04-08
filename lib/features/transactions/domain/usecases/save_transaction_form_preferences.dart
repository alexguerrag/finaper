import '../entities/transaction_form_preferences_entity.dart';
import '../repositories/transaction_form_preferences_repository.dart';

class SaveTransactionFormPreferences {
  const SaveTransactionFormPreferences(this._repository);

  final TransactionFormPreferencesRepository _repository;

  Future<void> call(TransactionFormPreferencesEntity preferences) {
    return _repository.savePreferences(preferences);
  }
}
