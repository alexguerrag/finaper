import 'package:finaper/app/di/app_locator.dart';
import 'package:finaper/features/settings/di/settings_module.dart';
import 'package:finaper/features/settings/domain/entities/app_settings_entity.dart';
import 'package:finaper/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:finaper/features/settings/domain/usecases/get_app_settings.dart';
import 'package:finaper/features/settings/domain/usecases/save_app_settings.dart';
import 'package:finaper/features/settings/presentation/controllers/settings_controller.dart';
import 'package:finaper/features/transactions/data/models/transaction_model.dart';
import 'package:finaper/features/transactions/domain/entities/transaction_entry_type.dart';
import 'package:finaper/features/transactions/presentation/controllers/transaction_list_controller.dart';
import 'package:finaper/features/transactions/presentation/widgets/transaction_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../helpers/locale_test_helper.dart';

// ── fake settings (no SQLite) ────────────────────────────────────────────────

class _FakeSettingsRepo implements AppSettingsRepository {
  @override
  Future<AppSettingsEntity> getAppSettings() async => AppSettingsEntity(
        id: AppSettingsEntity.singletonId,
        currencyCode: AppSettingsEntity.defaultCurrencyCode,
        localeCode: AppSettingsEntity.defaultLocaleCode,
        useSystemLocale: false,
        hasCompletedOnboarding: true,
        updatedAt: DateTime.now(),
      );

  @override
  Future<AppSettingsEntity> saveAppSettings(AppSettingsEntity s) async => s;
}

Future<void> _registerFakeSettings() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final repo = _FakeSettingsRepo();
  final controller = SettingsController(
    getAppSettings: GetAppSettings(repo),
    saveAppSettings: SaveAppSettings(repo),
  );
  await controller.load();
  AppLocator.register<SettingsModule>(
      SettingsModule.withController(controller));
}

TransactionModel _tx({
  required String id,
  required String description,
  required double amount,
  required bool isIncome,
  required DateTime date,
  String accountId = 'acc1',
  String accountName = 'Cuenta 1',
  String category = 'General',
  String categoryId = 'cat1',
}) {
  return TransactionModel(
    id: id,
    accountId: accountId,
    accountName: accountName,
    description: description,
    categoryId: categoryId,
    category: category,
    amount: amount,
    isIncome: isIncome,
    date: date,
    createdAt: date,
    note: '',
  );
}

final _today = DateTime.now();
final _yesterday = _today.subtract(const Duration(days: 1));
final _last5 = _today.subtract(const Duration(days: 5));
final _last40 = _today.subtract(const Duration(days: 40));

final _txIncome = _tx(
  id: '1',
  description: 'Sueldo',
  amount: 1000,
  isIncome: true,
  date: _today,
);
final _txExpense = _tx(
  id: '2',
  description: 'Supermercado',
  amount: 200,
  isIncome: false,
  date: _yesterday,
  category: 'Comida',
  categoryId: 'cat2',
);
final _txOld = _tx(
  id: '3',
  description: 'Viaje antiguo',
  amount: 500,
  isIncome: false,
  date: _last40,
);

void main() {
  setUpAll(() async => initTestLocales());

  group('TransactionListController', () {
    late TransactionListController controller;

    setUp(() {
      controller = TransactionListController();
      controller.setTransactions([_txIncome, _txExpense, _txOld]);
    });

    tearDown(() => controller.dispose());

    // ── totals ────────────────────────────────────────────────────────────

    test('totalIncome sums only income transactions', () {
      expect(controller.totalIncome, 1000.0);
    });

    test('totalExpense sums only expense transactions', () {
      expect(controller.totalExpense, 700.0);
    });

    test('incomeCount and expenseCount are correct', () {
      expect(controller.incomeCount, 1);
      expect(controller.expenseCount, 2);
    });

    // ── type filter ───────────────────────────────────────────────────────

    test('typeFilter=income shows only income', () {
      controller.setTypeFilter(TransactionTypeFilter.income);
      final visible = controller.visibleTransactions;
      expect(visible.length, 1);
      expect(visible.first.id, '1');
    });

    test('typeFilter=expense shows only expenses', () {
      controller.setTypeFilter(TransactionTypeFilter.expense);
      final visible = controller.visibleTransactions;
      expect(visible.every((t) => !t.isIncome), isTrue);
      expect(visible.length, 2);
    });

    test('typeFilter=all shows everything', () {
      controller.setTypeFilter(TransactionTypeFilter.income);
      controller.setTypeFilter(TransactionTypeFilter.all);
      expect(controller.visibleTransactions.length, 3);
    });

    // ── search ────────────────────────────────────────────────────────────

    test('search filters by description (case-insensitive)', () {
      controller.setSearchQuery('sueldo');
      expect(controller.visibleTransactions.length, 1);
      expect(controller.visibleTransactions.first.id, '1');
    });

    test('search filters by category', () {
      controller.setSearchQuery('comida');
      expect(controller.visibleTransactions.length, 1);
      expect(controller.visibleTransactions.first.id, '2');
    });

    test('search with no match returns empty list', () {
      controller.setSearchQuery('xyz_no_existe');
      expect(controller.visibleTransactions, isEmpty);
    });

    test('clearing search restores all results', () {
      controller.setSearchQuery('sueldo');
      controller.setSearchQuery('');
      expect(controller.visibleTransactions.length, 3);
    });

    // ── date filter ───────────────────────────────────────────────────────

    test('dateFilter=last7Days excludes transactions older than 7 days', () {
      controller.setAdvancedFilter(const TransactionListFilterState(
        dateFilter: TransactionDateFilterOption.last7Days,
        sortOption: TransactionSortOption.newestFirst,
      ));
      final ids = controller.visibleTransactions.map((t) => t.id).toList();
      expect(ids, containsAll(['1', '2']));
      expect(ids, isNot(contains('3')));
    });

    test('dateFilter=last30Days excludes 40-day-old transaction', () {
      controller.setAdvancedFilter(const TransactionListFilterState(
        dateFilter: TransactionDateFilterOption.last30Days,
        sortOption: TransactionSortOption.newestFirst,
      ));
      expect(
        controller.visibleTransactions.map((t) => t.id),
        isNot(contains('3')),
      );
    });

    test('dateFilter=custom filters by DateTimeRange', () {
      controller.setAdvancedFilter(TransactionListFilterState(
        dateFilter: TransactionDateFilterOption.custom,
        sortOption: TransactionSortOption.newestFirst,
        customRange: DateTimeRange(
          start: _last5.subtract(const Duration(days: 1)),
          end: _last5.add(const Duration(days: 1)),
        ),
      ));
      // None of our fixtures fall in that narrow range
      expect(controller.visibleTransactions, isEmpty);
    });

    // ── sort ──────────────────────────────────────────────────────────────

    test('sortOption=newestFirst orders by date descending', () {
      controller.setAdvancedFilter(const TransactionListFilterState(
        dateFilter: TransactionDateFilterOption.all,
        sortOption: TransactionSortOption.newestFirst,
      ));
      final dates = controller.visibleTransactions.map((t) => t.date).toList();
      for (var i = 0; i < dates.length - 1; i++) {
        expect(
            dates[i].isAfter(dates[i + 1]) || dates[i] == dates[i + 1], isTrue);
      }
    });

    test('sortOption=oldestFirst orders by date ascending', () {
      controller.setAdvancedFilter(const TransactionListFilterState(
        dateFilter: TransactionDateFilterOption.all,
        sortOption: TransactionSortOption.oldestFirst,
      ));
      final dates = controller.visibleTransactions.map((t) => t.date).toList();
      for (var i = 0; i < dates.length - 1; i++) {
        expect(dates[i].isBefore(dates[i + 1]) || dates[i] == dates[i + 1],
            isTrue);
      }
    });

    test('sortOption=highestAmount orders by amount descending', () {
      controller.setAdvancedFilter(const TransactionListFilterState(
        dateFilter: TransactionDateFilterOption.all,
        sortOption: TransactionSortOption.highestAmount,
      ));
      final amounts =
          controller.visibleTransactions.map((t) => t.amount).toList();
      for (var i = 0; i < amounts.length - 1; i++) {
        expect(amounts[i] >= amounts[i + 1], isTrue);
      }
    });

    test('sortOption=lowestAmount orders by amount ascending', () {
      controller.setAdvancedFilter(const TransactionListFilterState(
        dateFilter: TransactionDateFilterOption.all,
        sortOption: TransactionSortOption.lowestAmount,
      ));
      final amounts =
          controller.visibleTransactions.map((t) => t.amount).toList();
      for (var i = 0; i < amounts.length - 1; i++) {
        expect(amounts[i] <= amounts[i + 1], isTrue);
      }
    });

    // ── grouping ──────────────────────────────────────────────────────────
    // groupedTransactions calls AppFormatters.formatShortDate which needs
    // the Settings DI module — registered/cleared in this nested group.

    group('groupedTransactions', () {
      setUp(() async => _registerFakeSettings());
      tearDown(() => AppLocator.clear());

      test('keys contain Hoy and Ayer', () {
        final keys = controller.groupedTransactions.keys.toList();
        expect(keys, contains('Hoy'));
        expect(keys, contains('Ayer'));
      });
    });

    // ── clearFilters ──────────────────────────────────────────────────────

    test('clearFilters resets all state', () {
      controller.setSearchQuery('sueldo');
      controller.setTypeFilter(TransactionTypeFilter.income);
      controller.setAdvancedFilter(const TransactionListFilterState(
        dateFilter: TransactionDateFilterOption.last7Days,
        sortOption: TransactionSortOption.highestAmount,
      ));

      controller.clearFilters();

      expect(controller.searchQuery, isEmpty);
      expect(controller.typeFilter, TransactionTypeFilter.all);
      expect(controller.advancedFilter.dateFilter,
          TransactionDateFilterOption.all);
      expect(controller.advancedFilter.sortOption,
          TransactionSortOption.newestFirst);
      expect(controller.hasActiveFilters, isFalse);
      expect(controller.visibleTransactions.length, 3);
    });

    // ── visible summary (bug fix: filtros deben reflejarse en resumen) ────

    test('sin filtros: visibleIncome == totalIncome, visibleExpense == totalExpense', () {
      expect(controller.visibleIncome, controller.totalIncome);
      expect(controller.visibleExpense, controller.totalExpense);
      expect(controller.visibleNet, controller.totalNet);
    });

    test('summaryValue usa visibleNet cuando typeFilter=all sin filtros', () {
      expect(controller.summaryValue, controller.visibleNet);
    });

    test('filtro por cuenta: visibleIncome/visibleExpense solo de esa cuenta', () {
      final txAcc2Income = _tx(
        id: 'acc2-inc',
        description: 'Ingreso cuenta 2',
        amount: 3000,
        isIncome: true,
        date: _today,
        accountId: 'acc2',
        accountName: 'Cuenta 2',
      );
      final txAcc2Expense = _tx(
        id: 'acc2-exp',
        description: 'Gasto cuenta 2',
        amount: 500,
        isIncome: false,
        date: _today,
        accountId: 'acc2',
        accountName: 'Cuenta 2',
      );
      controller.setTransactions(
          [_txIncome, _txExpense, _txOld, txAcc2Income, txAcc2Expense]);
      controller.setSelectedAccount('acc2');

      expect(controller.visibleIncome, 3000.0);
      expect(controller.visibleExpense, 500.0);
      expect(controller.visibleNet, 2500.0);
      // totales globales no deben cambiar
      expect(controller.totalIncome, 4000.0);
      expect(controller.totalExpense, 1200.0);
    });

    test('filtro por fecha: visibleIncome/visibleExpense solo del período', () {
      controller.setAdvancedFilter(
        controller.advancedFilter.copyWith(
          dateFilter: TransactionDateFilterOption.last7Days,
        ),
      );
      // _txOld está a 40 días → excluido
      expect(controller.visibleIncome, 1000.0);  // _txIncome (hoy)
      expect(controller.visibleExpense, 200.0);   // _txExpense (ayer)
      expect(controller.visibleNet, 800.0);
      // totalExpense global sigue incluyendo _txOld
      expect(controller.totalExpense, 700.0);
    });

    test('filtro por búsqueda: visibleIncome/visibleExpense reflejan resultados', () {
      controller.setSearchQuery('Supermercado');
      expect(controller.visibleIncome, 0.0);
      expect(controller.visibleExpense, 200.0);
      expect(controller.visibleNet, -200.0);
    });

    test('filtro typeFilter=income: summaryValue == visibleIncome', () {
      controller.setTypeFilter(TransactionTypeFilter.income);
      expect(controller.summaryValue, controller.visibleIncome);
      expect(controller.summaryValue, 1000.0);
    });

    test('filtro typeFilter=expense: summaryValue == visibleExpense', () {
      controller.setTypeFilter(TransactionTypeFilter.expense);
      expect(controller.summaryValue, controller.visibleExpense);
      expect(controller.summaryValue, 700.0);
    });

    test('transferencias excluidas de visibleIncome y visibleExpense', () {
      final txTransfer = TransactionModel(
        id: 'transfer-1',
        description: 'Transferencia',
        category: 'Transferencia',
        amount: 9999,
        isIncome: false,
        date: _today,
        createdAt: _today,
        note: '',
        entryType: TransactionEntryType.transferOut,
        transferGroupId: 'tg1',
      );
      controller.setTransactions([_txIncome, _txExpense, txTransfer]);
      expect(controller.visibleIncome, 1000.0);
      expect(controller.visibleExpense, 200.0);
      expect(controller.visibleNet, 800.0);
    });

    // ── cache ─────────────────────────────────────────────────────────────

    test('visibleTransactions returns cached instance when state unchanged',
        () {
      final first = controller.visibleTransactions;
      final second = controller.visibleTransactions;
      expect(identical(first, second), isTrue);
    });

    test('cache is invalidated after filter change', () {
      final before = controller.visibleTransactions;
      controller.setTypeFilter(TransactionTypeFilter.income);
      final after = controller.visibleTransactions;
      expect(identical(before, after), isFalse);
    });

    // ── notifyListeners ───────────────────────────────────────────────────

    test('notifies listeners when search query changes', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setSearchQuery('test');
      expect(notified, isTrue);
    });

    test('does not notify listeners when search query is unchanged', () {
      controller.setSearchQuery('test');
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setSearchQuery('test');
      expect(notified, isFalse);
    });
  });
}
