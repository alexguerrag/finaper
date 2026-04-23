import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/budgets/domain/entities/budget_entity.dart';
import '../../features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Per-session flags — one alert per type per cold start
  static bool _budgetNotifiedThisSession = false;
  static bool _recurringNotifiedThisSession = false;

  // ── init ──────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── budget alerts ─────────────────────────────────────────────────────────

  static Future<void> checkAndNotifyBudgets(List<BudgetEntity> budgets) async {
    if (_budgetNotifiedThisSession || !_initialized) return;
    _budgetNotifiedThisSession = true;

    final exceeded = budgets.where((b) => b.isExceeded).toList();
    final atRisk =
        budgets.where((b) => !b.isExceeded && b.progress >= 0.8).toList();

    if (exceeded.isEmpty && atRisk.isEmpty) return;

    final String title;
    final String body;

    if (exceeded.isNotEmpty && atRisk.isNotEmpty) {
      title = 'Presupuestos en alerta';
      body =
          '${exceeded.length} excedido${exceeded.length > 1 ? 's' : ''} y ${atRisk.length} en zona de cuidado este mes.';
    } else if (exceeded.isNotEmpty) {
      title = exceeded.length == 1
          ? 'Presupuesto excedido'
          : 'Presupuestos excedidos';
      body = exceeded.length == 1
          ? '${exceeded.first.categoryName} superó su límite este mes.'
          : '${exceeded.length} categorías superaron su límite este mes.';
    } else {
      title = atRisk.length == 1
          ? 'Presupuesto en zona de cuidado'
          : 'Presupuestos en zona de cuidado';
      body = atRisk.length == 1
          ? '${atRisk.first.categoryName} lleva más del 80% de su límite.'
          : '${atRisk.length} categorías llevan más del 80% de su límite.';
    }

    await _show(id: 1, title: title, body: body);
  }

  // ── recurring alerts ──────────────────────────────────────────────────────

  static Future<void> checkAndNotifyRecurring(
      List<RecurringTransactionEntity> items) async {
    if (_recurringNotifiedThisSession || !_initialized) return;
    _recurringNotifiedThisSession = true;

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    final overdue = items
        .where(
            (item) => item.isActive && item.nextRunDate.isBefore(todayMidnight))
        .toList();

    if (overdue.isEmpty) return;

    final String title;
    final String body;

    if (overdue.length == 1) {
      title = 'Recurrente vencida';
      body = '"${overdue.first.description}" está pendiente de procesar.';
    } else {
      title = 'Recurrentes vencidas';
      body =
          '${overdue.length} movimientos recurrentes están pendientes de procesar.';
    }

    await _show(id: 2, title: title, body: body);
  }

  // ── session reset (call on app resume if desired) ─────────────────────────

  static void resetSession() {
    _budgetNotifiedThisSession = false;
    _recurringNotifiedThisSession = false;
  }

  // ── private ───────────────────────────────────────────────────────────────

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'finaper_alerts',
          'Alertas Finaper',
          channelDescription: 'Alertas de presupuesto y recurrentes',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: false,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }
}
