import 'package:finaper/features/export_backup/data/services/backup_payload_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = BackupPayloadCodec();

  test('valida respaldo actual y construye preview consistente', () {
    const rawContent = '''
{
  "exported_at": "2026-04-11T13:00:00.000",
  "app": {
    "name": "Finaper",
    "database_version": 9,
    "backup_format_version": 1,
    "format": "json-backup"
  },
  "summary": {
    "accounts_count": 1,
    "categories_count": 2,
    "transactions_count": 1,
    "budgets_count": 0,
    "goals_count": 0,
    "recurring_transactions_count": 0,
    "has_transaction_form_preferences": true
  },
  "settings": {
    "id": 1,
    "currency_code": "CLP",
    "locale_code": "es_CL",
    "use_system_locale": 1,
    "updated_at": "2026-04-11T13:00:00.000"
  },
  "transaction_form_preferences": {
    "id": 1,
    "last_account_id": "acc-main",
    "last_expense_category_id": "cat-exp-other",
    "last_income_category_id": "cat-inc-other",
    "last_quick_date_option": "today"
  },
  "accounts": [
    {
      "id": "acc-main",
      "name": "Cuenta principal",
      "type": "cash",
      "icon_code": 123,
      "color_value": 456,
      "initial_balance": 1000,
      "is_archived": 0,
      "created_at": "2026-04-10T10:00:00.000"
    }
  ],
  "categories": [
    {
      "id": "cat-exp-other",
      "name": "Otros",
      "kind": "expense",
      "icon_code": 1,
      "color_value": 2,
      "is_system": 1,
      "created_at": "2026-04-10T10:00:00.000"
    },
    {
      "id": "cat-inc-other",
      "name": "Otros",
      "kind": "income",
      "icon_code": 1,
      "color_value": 2,
      "is_system": 1,
      "created_at": "2026-04-10T10:00:00.000"
    }
  ],
  "transactions": [
    {
      "id": "tx-1",
      "account_id": "acc-main",
      "account_name": "Cuenta principal",
      "description": "Salario",
      "category_id": "cat-inc-other",
      "category": "Otros",
      "amount": 500,
      "is_income": 1,
      "date": "2026-04-11T09:00:00.000",
      "note": null,
      "color_value": 2,
      "generated_from_recurring_id": null
    }
  ],
  "budgets": [],
  "goals": [],
  "recurring_transactions": []
}
''';

    final result = codec.parseAndValidatePayload(
      fileName: 'backup.json',
      rawContent: rawContent,
    );

    expect(result.preview.fileName, 'backup.json');
    expect(result.preview.databaseVersion, 9);
    expect(result.preview.backupFormatVersion, 1);
    expect(result.preview.accountsCount, 1);
    expect(result.preview.categoriesCount, 2);
    expect(result.preview.transactionsCount, 1);
    expect(result.preview.hasTransactionFormPreferences, isTrue);
    expect(result.warnings, isEmpty);
  });

  test('acepta respaldo legado y agrega warnings de compatibilidad', () {
    const rawContent = '''
{
  "exported_at": "2026-03-29T03:10:00.000",
  "app": {
    "name": "Finaper",
    "database_version": 7,
    "format": "json-backup"
  },
  "settings": {
    "id": 1,
    "currency_code": "CLP",
    "locale_code": "es_CL",
    "use_system_locale": 1,
    "updated_at": "2026-03-29T03:10:00.000"
  },
  "accounts": [
    {
      "id": "acc-main",
      "name": "Cuenta principal",
      "type": "cash",
      "icon_code": 123,
      "color_value": 456,
      "is_archived": 0,
      "created_at": "2026-03-20T10:00:00.000"
    }
  ],
  "categories": [],
  "transactions": [],
  "budgets": [],
  "goals": [],
  "recurring_transactions": []
}
''';

    final result = codec.parseAndValidatePayload(
      fileName: 'legacy.json',
      rawContent: rawContent,
    );

    expect(result.preview.databaseVersion, 7);
    expect(result.preview.backupFormatVersion, 1);
    expect(result.preview.hasTransactionFormPreferences, isFalse);
    expect(result.payload['transaction_form_preferences'], isA<Map<String, dynamic>>());
    expect(result.warnings, hasLength(2));
    expect(
      result.warnings.first,
      contains('respaldo legado'),
    );
    expect(
      result.warnings.last,
      contains('preferencias rápidas del formulario'),
    );

    final accounts = result.payload['accounts'] as List<Map<String, dynamic>>;
    expect(accounts.first['initial_balance'], 0);
  });

  test('rechaza archivos que no correspondan a respaldo Finaper', () {
    const rawContent = '''
{
  "app": {
    "name": "OtraApp",
    "database_version": 9,
    "backup_format_version": 1,
    "format": "json-backup"
  },
  "accounts": [],
  "categories": [],
  "transactions": [],
  "budgets": [],
  "goals": [],
  "recurring_transactions": []
}
''';

    expect(
      () => codec.parseAndValidatePayload(
        fileName: 'invalid.json',
        rawContent: rawContent,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('no pertenece a Finaper'),
        ),
      ),
    );
  });

  test('rechaza respaldos sin bloques críticos', () {
    final payload = <String, dynamic>{
      'app': {
        'name': 'Finaper',
        'database_version': 9,
        'backup_format_version': 1,
        'format': 'json-backup',
      },
      'accounts': <Map<String, dynamic>>[],
      'categories': <Map<String, dynamic>>[],
      'transactions': <Map<String, dynamic>>[],
      'budgets': <Map<String, dynamic>>[],
      'goals': <Map<String, dynamic>>[],
    };

    expect(
      () => codec.validatePayload(
        fileName: 'broken.json',
        payload: payload,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('movimientos recurrentes'),
        ),
      ),
    );
  });
}
