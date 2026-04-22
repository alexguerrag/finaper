import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  static const String _databaseName = 'finaper.db';
  static const int _databaseVersion = 14;

  static const String defaultAccountId = 'acc-cash-main';
  static const String defaultAccountName = 'Cuenta principal';
  static const String defaultExpenseCategoryId = 'cat-exp-other';
  static const String defaultIncomeCategoryId = 'cat-inc-other';

  static const String transferExpenseCategoryId = 'cat-exp-transfer';
  static const String transferExpenseCategoryName = 'Transferencia enviada';
  static const String transferIncomeCategoryId = 'cat-inc-transfer';
  static const String transferIncomeCategoryName = 'Transferencia recibida';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  @visibleForTesting
  void overrideForTest(Database db) => _database = db;

  @visibleForTesting
  static void resetForTest() => _database = null;

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
      await _createTransactionFormPreferencesTable(db);
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

      if (oldVersion < 8) {
        await _createTransactionFormPreferencesTable(db);
      }

      if (oldVersion < 9) {
        await _addColumnIfMissing(
          db,
          'accounts',
          'initial_balance',
          'REAL NOT NULL DEFAULT 0',
        );
      }

      if (oldVersion < 10) {
        await _addColumnIfMissing(
          db,
          'transactions',
          'entry_type',
          "TEXT NOT NULL DEFAULT 'standard'",
        );
        await _addColumnIfMissing(
          db,
          'transactions',
          'transfer_group_id',
          'TEXT',
        );
        await _addColumnIfMissing(
          db,
          'transactions',
          'counterparty_account_id',
          'TEXT',
        );
        await _addColumnIfMissing(
          db,
          'transactions',
          'counterparty_account_name',
          'TEXT',
        );

        await db.rawUpdate('''
          UPDATE transactions
          SET entry_type = 'standard'
          WHERE entry_type IS NULL OR entry_type = ''
        ''');
      }

      if (oldVersion < 11) {
        await _addColumnIfMissing(
          db,
          'transactions',
          'created_at',
          "TEXT NOT NULL DEFAULT ''",
        );

        // Backfill seguro: para filas existentes usamos `date` como valor
        // de createdAt. Es la mejor aproximación disponible y preserva el
        // orden relativo original.
        await db.rawUpdate('''
          UPDATE transactions
          SET created_at = date
          WHERE created_at IS NULL OR created_at = ''
        ''');
      }

      if (oldVersion < 12) {
        await _addColumnIfMissing(
          db,
          'app_settings',
          'has_completed_onboarding',
          'INTEGER NOT NULL DEFAULT 0',
        );
      }

      if (oldVersion < 13) {
        await _addColumnIfMissing(
          db,
          'categories',
          'is_archived',
          'INTEGER NOT NULL DEFAULT 0',
        );
      }

      if (oldVersion < 14) {
        // Rename categories
        await db.rawUpdate(
          "UPDATE categories SET name = 'Casa' WHERE id = 'cat-exp-home'",
        );
        await db.rawUpdate(
          "UPDATE categories SET name = 'Ocio / Entretenimiento' WHERE id = 'cat-exp-entertainment'",
        );
        await db.rawUpdate(
          "UPDATE categories SET name = 'Suscripciones / Streaming' WHERE id = 'cat-exp-subscriptions'",
        );
        await db.rawUpdate(
          "UPDATE categories SET name = 'Honorarios / Freelance' WHERE id = 'cat-inc-freelance'",
        );
        await db.rawUpdate(
          "UPDATE categories SET name = 'Bonos' WHERE id = 'cat-inc-bonus'",
        );

        // Update denormalized category name in transactions
        await db.rawUpdate(
          "UPDATE transactions SET category = 'Casa' WHERE category_id = 'cat-exp-home'",
        );
        await db.rawUpdate(
          "UPDATE transactions SET category = 'Ocio / Entretenimiento' WHERE category_id = 'cat-exp-entertainment'",
        );
        await db.rawUpdate(
          "UPDATE transactions SET category = 'Suscripciones / Streaming' WHERE category_id = 'cat-exp-subscriptions'",
        );
        await db.rawUpdate(
          "UPDATE transactions SET category = 'Honorarios / Freelance' WHERE category_id = 'cat-inc-freelance'",
        );
        await db.rawUpdate(
          "UPDATE transactions SET category = 'Bonos' WHERE category_id = 'cat-inc-bonus'",
        );

        // Update denormalized category name in recurring_transactions
        await db.rawUpdate(
          "UPDATE recurring_transactions SET category_name = 'Casa' WHERE category_id = 'cat-exp-home'",
        );
        await db.rawUpdate(
          "UPDATE recurring_transactions SET category_name = 'Ocio / Entretenimiento' WHERE category_id = 'cat-exp-entertainment'",
        );
        await db.rawUpdate(
          "UPDATE recurring_transactions SET category_name = 'Suscripciones / Streaming' WHERE category_id = 'cat-exp-subscriptions'",
        );
        await db.rawUpdate(
          "UPDATE recurring_transactions SET category_name = 'Honorarios / Freelance' WHERE category_id = 'cat-inc-freelance'",
        );
        await db.rawUpdate(
          "UPDATE recurring_transactions SET category_name = 'Bonos' WHERE category_id = 'cat-inc-bonus'",
        );

        // Update denormalized category name in budgets
        await db.rawUpdate(
          "UPDATE budgets SET category_name = 'Casa' WHERE category_id = 'cat-exp-home'",
        );
        await db.rawUpdate(
          "UPDATE budgets SET category_name = 'Ocio / Entretenimiento' WHERE category_id = 'cat-exp-entertainment'",
        );
        await db.rawUpdate(
          "UPDATE budgets SET category_name = 'Suscripciones / Streaming' WHERE category_id = 'cat-exp-subscriptions'",
        );
        await db.rawUpdate(
          "UPDATE budgets SET category_name = 'Honorarios / Freelance' WHERE category_id = 'cat-inc-freelance'",
        );
        await db.rawUpdate(
          "UPDATE budgets SET category_name = 'Bonos' WHERE category_id = 'cat-inc-bonus'",
        );
      }

      await _seedCategories(db);
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
        initial_balance REAL NOT NULL DEFAULT 0,
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
        is_archived INTEGER NOT NULL DEFAULT 0,
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
        created_at TEXT NOT NULL DEFAULT '',
        note TEXT,
        color_value INTEGER NOT NULL,
        entry_type TEXT NOT NULL DEFAULT 'standard',
        transfer_group_id TEXT,
        counterparty_account_id TEXT,
        counterparty_account_name TEXT,
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
        has_completed_onboarding INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createTransactionFormPreferencesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_form_preferences (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        last_account_id TEXT,
        last_expense_category_id TEXT,
        last_income_category_id TEXT,
        last_quick_date_option TEXT
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date_created_at ON transactions(date DESC, created_at DESC)',
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
      'CREATE INDEX IF NOT EXISTS idx_transactions_entry_type ON transactions(entry_type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_transfer_group_id ON transactions(transfer_group_id)',
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
        'initial_balance': 0.0,
        'is_archived': 0,
        'created_at': now,
      },
      {
        'id': 'acc-savings-main',
        'name': 'Ahorros',
        'type': 'savings',
        'icon_code': Icons.savings_rounded.codePoint,
        'color_value': Colors.green.toARGB32(),
        'initial_balance': 0.0,
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
        'name': 'Casa',
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
        'name': 'Ocio / Entretenimiento',
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
        'name': 'Suscripciones / Streaming',
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
        'id': transferExpenseCategoryId,
        'name': transferExpenseCategoryName,
        'kind': 'expense',
        'icon_code': Icons.swap_horiz_rounded.codePoint,
        'color_value': Colors.blueGrey.toARGB32(),
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
        'name': 'Honorarios / Freelance',
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
        'name': 'Bonos',
        'kind': 'income',
        'icon_code': Icons.card_giftcard_rounded.codePoint,
        'color_value': Colors.amber.toARGB32(),
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': transferIncomeCategoryId,
        'name': transferIncomeCategoryName,
        'kind': 'income',
        'icon_code': Icons.swap_horiz_rounded.codePoint,
        'color_value': Colors.blueGrey.toARGB32(),
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
      // --- New expense categories (v14) ---
      {
        'id': 'cat-exp-car',
        'name': 'Automóvil',
        'kind': 'expense',
        'icon_code': Icons.directions_car_rounded.codePoint,
        'color_value': Colors.blueGrey.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-fuel',
        'name': 'Combustible',
        'kind': 'expense',
        'icon_code': Icons.local_gas_station_rounded.codePoint,
        'color_value': Colors.deepOrange.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-tolls',
        'name': 'Autopistas / Peajes',
        'kind': 'expense',
        'icon_code': Icons.toll_rounded.codePoint,
        'color_value': Colors.brown.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-supermarket',
        'name': 'Supermercado',
        'kind': 'expense',
        'icon_code': Icons.shopping_cart_rounded.codePoint,
        'color_value': Colors.green.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-clothing',
        'name': 'Ropa y Calzado',
        'kind': 'expense',
        'icon_code': Icons.checkroom_rounded.codePoint,
        'color_value': Colors.pink.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-home-services',
        'name': 'Servicios Hogar',
        'kind': 'expense',
        'icon_code': Icons.home_repair_service_rounded.codePoint,
        'color_value': Colors.teal.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-rent',
        'name': 'Arriendo / Hipoteca',
        'kind': 'expense',
        'icon_code': Icons.house_rounded.codePoint,
        'color_value': Colors.brown.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-snacks',
        'name': 'Snack / Bebidas',
        'kind': 'expense',
        'icon_code': Icons.local_cafe_rounded.codePoint,
        'color_value': Colors.orange.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-restaurant',
        'name': 'Restaurante',
        'kind': 'expense',
        'icon_code': Icons.lunch_dining_rounded.codePoint,
        'color_value': Colors.red.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-comms',
        'name': 'Comunicaciones',
        'kind': 'expense',
        'icon_code': Icons.phone_android_rounded.codePoint,
        'color_value': Colors.indigo.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-sports',
        'name': 'Deportes',
        'kind': 'expense',
        'icon_code': Icons.fitness_center_rounded.codePoint,
        'color_value': Colors.green.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-dental',
        'name': 'Dental',
        'kind': 'expense',
        'icon_code': Icons.healing_rounded.codePoint,
        'color_value': Colors.cyan.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-pharmacy',
        'name': 'Farmacia',
        'kind': 'expense',
        'icon_code': Icons.local_pharmacy_rounded.codePoint,
        'color_value': Colors.red.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-hygiene',
        'name': 'Artículos de Aseo',
        'kind': 'expense',
        'icon_code': Icons.cleaning_services_rounded.codePoint,
        'color_value': Colors.blue.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-pets',
        'name': 'Mascotas',
        'kind': 'expense',
        'icon_code': Icons.pets_rounded.codePoint,
        'color_value': Colors.amber.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-insurance',
        'name': 'Seguros',
        'kind': 'expense',
        'icon_code': Icons.security_rounded.codePoint,
        'color_value': Colors.blueGrey.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-bills',
        'name': 'Facturas',
        'kind': 'expense',
        'icon_code': Icons.receipt_long_rounded.codePoint,
        'color_value': Colors.deepPurple.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-financial',
        'name': 'Gasto Financiero',
        'kind': 'expense',
        'icon_code': Icons.currency_exchange_rounded.codePoint,
        'color_value': Colors.deepOrange.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-condo',
        'name': 'Gastos Edificio / Condominio',
        'kind': 'expense',
        'icon_code': Icons.apartment_rounded.codePoint,
        'color_value': Colors.brown.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-gifts',
        'name': 'Regalos',
        'kind': 'expense',
        'icon_code': Icons.card_giftcard_rounded.codePoint,
        'color_value': Colors.pink.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-donations',
        'name': 'Donaciones',
        'kind': 'expense',
        'icon_code': Icons.volunteer_activism_rounded.codePoint,
        'color_value': Colors.purple.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-exp-travel',
        'name': 'Viajes / Vacaciones',
        'kind': 'expense',
        'icon_code': Icons.flight_rounded.codePoint,
        'color_value': Colors.cyan.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      // --- New income categories (v14) ---
      {
        'id': 'cat-inc-rent-received',
        'name': 'Arriendo Recibido',
        'kind': 'income',
        'icon_code': Icons.domain_rounded.codePoint,
        'color_value': Colors.teal.toARGB32(),
        'is_system': 0,
        'created_at': now,
      },
      {
        'id': 'cat-inc-pension',
        'name': 'Pensión / Jubilación',
        'kind': 'income',
        'icon_code': Icons.elderly_rounded.codePoint,
        'color_value': Colors.amber.toARGB32(),
        'is_system': 0,
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
        orderBy: 'date DESC, created_at DESC',
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
