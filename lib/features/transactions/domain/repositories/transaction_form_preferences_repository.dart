import '../entities/transaction_form_preferences_entity.dart';

abstract class TransactionFormPreferencesRepository {
  Future<TransactionFormPreferencesEntity> getPreferences();
  Future<void> savePreferences(TransactionFormPreferencesEntity preferences);
}
