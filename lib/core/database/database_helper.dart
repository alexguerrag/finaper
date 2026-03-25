import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  static const String _databaseName = 'finaper.db';
  static const int _databaseVersion = 7;

  static const String defaultAccountId = 'acc-cash-main';
  static const String defaultAccountName = 'Cuenta principal';
  static const String defaultExpenseCategoryId = 'cat-exp-other';
  static const String defaultIncomeCategoryId = 'cat-inc-other';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e, s) {
      debugPrint('Database open error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await _createAccountsTable(db);
      await _createCategoriesTable(db);
      await _createTransactionsTable(db);
      await _createBudgetsTable(db);
      await _createGoalsTable(db);
      await _createRecurringTransactionsTable(db);
      await _createAppSettingsTable(db);
      await _seedAccounts(db);
      await _seedCategories(db);
      await _seedAppSettings(db);
      await _createIndexes(db);
    } catch (e, s) {
      debugPrint('Database create error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 3) {
        await _createAccountsTable(db);
        await _createCategoriesTable(db);
        await _seedAccounts(db);
        await _seedCategories(db);

        final hasTransactions = await _tableExists(db, 'transactions');
        if (hasTransactions) {
          await _addColumnIfMissing(
            db,
            'transactions',
            'account_id',
            'TEXT',
          );
          await _addColumnIfMissing(
            db,
            'transactions',
            'account_name',
            'TEXT',
          );
          await _addColumnIfMissing(
            db,
            'transactions',
            'category_id',
            'TEXT',
          );

          await _backfillLegacyTransactions(db);
        } else {
          await _createTransactionsTable(db);
        }
      }

      if (oldVersion < 4) {
        await _createBudgetsTable(db);
      }

      if (oldVersion < 5) {
        await _createGoalsTable(db);
      }

      if (oldVersion < 6) {
        await _createRecurringTransactionsTable(db);
        await _addColumnIfMissing(
          db,
          'transactions',
          'generated_from_recurring_id',
          'TEXT',
        );
      }

      if (oldVersion < 7) {
        await _createAppSettingsTable(db);
        await _seedAppSettings(db);
      }

      await _createIndexes(db);
    } catch (e, s) {
      debugPrint('Database migration error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<void> _createAccountsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        kind TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        is_system INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        account_name TEXT NOT NULL,
        description TEXT NOT NULL,
        category_id TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        is_income INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        color_value INTEGER NOT NULL,
        generated_from_recurring_id TEXT,
        FOREIGN KEY(account_id) REFERENCES accounts(id) ON DELETE RESTRICT,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT
      )
    ''');
  }

  Future<void> _createBudgetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        month_key TEXT NOT NULL,
        amount_limit REAL NOT NULL,
        color_value INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT,
        UNIQUE(category_id, month_key)
      )
    ''');
  }

  Future<void> _createGoalsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0,
        target_date TEXT,
        color_value INTEGER NOT NULL,
        icon_code INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createRecurringTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        account_name TEXT NOT NULL,
        description TEXT NOT NULL,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        amount REAL NOT NULL,
        is_income INTEGER NOT NULL,
        note TEXT,
        color_value INTEGER NOT NULL,
        frequency TEXT NOT NULL,
        interval_value INTEGER NOT NULL DEFAULT 1,
        start_date TEXT NOT NULL,
        end_date TEXT,
        next_run_date TEXT NOT NULL,
        last_generated_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(account_id) REFERENCES accounts(id) ON DELETE RESTRICT,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT
      )
    ''');
  }

  Future<void> _createAppSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        currency_code TEXT NOT NULL,
        locale_code TEXT NOT NULL,
        use_system_locale INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(is_income)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_category_id ON transactions(category_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON transactions(account_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_generated_from_recurring_id ON transactions(generated_from_recurring_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_categories_kind_name ON categories(kind, name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_accounts_name ON accounts(name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_budgets_month_key ON budgets(month_key)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_budgets_category_month ON budgets(category_id, month_key)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_goals_completed ON goals(is_completed)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_goals_target_date ON goals(target_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recurring_transactions_active_next_run ON recurring_transactions(is_active, next_run_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recurring_transactions_category_id ON recurring_transactions(category_id)',
    );
  }

  Future<void> _seedAccounts(Database db) async {
    final now = DateTime.now().toIso8601String();

    final accounts = <Map<String, dynamic>>[
      {
        'id': defaultAccountId,
        'name': defaultAccountName,
        'type': 'cash',
        'icon_code': Icons.account_balance_wallet_rounded.codePoint,
        'color_value': Colors.blue.toARGB32(),
        'is_archived': 0,
        'created_at': now,
      },
      {
        'id': 'acc-savings-main',
        'name': 'Ahorros',
        'type': 'savings',
        'icon_code': Icons.savings_rounded.codePoint,
        'color_value': Colors.green.toARGB32(),
        'is_archived': 0,
        'created_at': now,
      },
    ];

    final batch = db.batch();
    for (final account in accounts) {
      batch.insert(
        'accounts',
        account,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedCategories(Database db) async {
    final now = DateTime.now().toIso8601String();

    final categories = <Map<String, dynamic>>[
      {
        'id': 'cat-exp-food',
        'name': 'Alimentación',
        'kind': 'expense',
        'icon_code': Icons.restaurant_rounded.codePoint,
        'color_value': Colors.orange.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'cat-exp-transport',
        'name': 'Transporte',
        'kind': 'expense',
        'icon_code': Icons.directions_car_rounded.codePoint,
        'color_value': Colors.indigo.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'cat-exp-home',
        'name': 'Hogar',
        'kind': 'expense',
        'icon_code': Icons.home_rounded.codePoint,
        'color_value': Colors.brown.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'cat-exp-health',
        'name': 'Salud',
        'kind': 'expense',
        'icon_code': Icons.favorite_rounded.codePoint,
        'color_value': Colors.red.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'cat-exp-entertainment',
        'name': 'Entretenimiento',
        'kind': 'expense',
        'icon_code': Icons.movie_rounded.codePoint,
        'color_value': Colors.purple.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'cat-exp-services',
        'name': 'Servicios',
        'kind': 'expense',
        'icon_code': Icons.power_rounded.codePoint,
        'color_value': Colors.teal.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'cat-exp-education',
        'name': 'Educación',
        'kind': 'expense',
        'icon_code': Icons.school_rounded.codePoint,
        'color_value': Colors.cyan.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'cat-exp-subscriptions',
        'name': 'Suscripciones',
        'kind': 'expense',
        'icon_code': Icons.subscriptions_rounded.codePoint,
        'color_value': Colors.deepPurple.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'cat-exp-shopping',
        'name': 'Compras',
        'kind': 'expense',
        'icon_code': Icons.shopping_bag_rounded.codePoint,
        'color_value': Colors.pink.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': defaultExpenseCategoryId,
        'name': 'Otros',
        'kind': 'expense',
        'icon_code': Icons.more_horiz_rounded.codePoint,
        'color_value': Colors.grey.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'cat-inc-salary',
        'name': 'Salario',
        'kind': 'income',
        'icon_code': Icons.payments_rounded.codePoint,
        'color_value': Colors.green.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'cat-inc-freelance',
        'name': 'Freelance',
        'kind': 'income',
        'icon_code': Icons.work_rounded.codePoint,
        'color_value': Colors.lightGreen.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'cat-inc-investments',
        'name': 'Inversiones',
        'kind': 'income',
        'icon_code': Icons.trending_up_rounded.codePoint,
        'color_value': Colors.teal.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'cat-inc-reimbursement',
        'name': 'Reembolso',
        'kind': 'income',
        'icon_code': Icons.replay_circle_filled_rounded.codePoint,
        'color_value': Colors.blue.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'cat-inc-bonus',
        'name': 'Bono',
        'kind': 'income',
        'icon_code': Icons.card_giftcard_rounded.codePoint,
        'color_value': Colors.amber.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': defaultIncomeCategoryId,
        'name': 'Otros',
        'kind': 'income',
        'icon_code': Icons.more_horiz_rounded.codePoint,
        'color_value': Colors.grey.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
    ];

    final batch = db.batch();
    for (final category in categories) {
      batch.insert(
        'categories',
        category,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedAppSettings(Database db) async {
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'app_settings',
      {
        'id': 1,
        'currency_code': 'CLP',
        'locale_code': 'es_CL',
        'use_system_locale': 1,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _backfillLegacyTransactions(Database db) async {
    await db.rawUpdate('''
      UPDATE transactions
      SET account_id = ?
      WHERE account_id IS NULL OR account_id = ''
    ''', [defaultAccountId]);

    await db.rawUpdate('''
      UPDATE transactions
      SET account_name = ?
      WHERE account_name IS NULL OR account_name = ''
    ''', [defaultAccountName]);

    await db.rawUpdate('''
      UPDATE transactions
      SET category_id = COALESCE(
        (
          SELECT c.id
          FROM categories c
          WHERE c.name = transactions.category
            AND c.kind = CASE
              WHEN transactions.is_income = 1 THEN 'income'
              ELSE 'expense'
            END
          LIMIT 1
        ),
        CASE
          WHEN transactions.is_income = 1 THEN ?
          ELSE ?
        END
      )
      WHERE category_id IS NULL OR category_id = ''
    ''', [defaultIncomeCategoryId, defaultExpenseCategoryId]);
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String tableName,
    String columnName,
    String columnType,
  ) async {
    final exists = await _columnExists(db, tableName, columnName);
    if (exists) return;

    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN $columnName $columnType',
    );
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table' AND name = ?
      ''',
      [tableName],
    );

    return result.isNotEmpty;
  }

  Future<bool> _columnExists(
    Database db,
    String tableName,
    String columnName,
  ) async {
    final result = await db.rawQuery('PRAGMA table_info($tableName)');
    return result.any((column) => column['name'] == columnName);
  }

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    try {
      final db = await database;
      return await db.insert(
        'transactions',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, s) {
      debugPrint('insertTransaction error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryAllTransactions() async {
    try {
      final db = await database;
      return await db.query(
        'transactions',
        orderBy: 'date DESC',
      );
    } catch (e, s) {
      debugPrint('queryAllTransactions error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<int> updateTransaction(
    String id,
    Map<String, dynamic> row,
  ) async {
    try {
      final db = await database;
      return await db.update(
        'transactions',
        row,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, s) {
      debugPrint('updateTransaction error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<int> deleteTransaction(String id) async {
    try {
      final db = await database;
      return await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, s) {
      debugPrint('deleteTransaction error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      final db = _database;
      if (db != null) {
        await db.close();
        _database = null;
      }
    } catch (e, s) {
      debugPrint('Database close error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
