import '../../domain/entities/transaction_form_preferences_entity.dart';
import '../../domain/repositories/transaction_form_preferences_repository.dart';
import '../local/transaction_form_preferences_local_datasource.dart';
import '../models/transaction_form_preferences_model.dart';

class TransactionFormPreferencesRepositoryImpl
    implements TransactionFormPreferencesRepository {
  const TransactionFormPreferencesRepositoryImpl(this._localDataSource);

  final TransactionFormPreferencesLocalDataSource _localDataSource;

  @override
  Future<TransactionFormPreferencesEntity> getPreferences() {
    return _localDataSource.getPreferences();
  }

  @override
  Future<void> savePreferences(
    TransactionFormPreferencesEntity preferences,
  ) async {
    final model = TransactionFormPreferencesModel.fromEntity(preferences);
    await _localDataSource.savePreferences(model);
  }
}
