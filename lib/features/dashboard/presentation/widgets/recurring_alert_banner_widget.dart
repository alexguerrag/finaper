import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../recurring_transactions/di/recurring_transactions_registry.dart';
import '../../../recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import '../../../recurring_transactions/domain/usecases/get_recurring_transactions.dart';

class RecurringAlertBannerWidget extends StatefulWidget {
  const RecurringAlertBannerWidget({
    super.key,
    required this.refreshToken,
    this.onManagePressed,
  });

  final int refreshToken;
  final VoidCallback? onManagePressed;

  @override
  State<RecurringAlertBannerWidget> createState() =>
      _RecurringAlertBannerWidgetState();
}

class _RecurringAlertBannerWidgetState
    extends State<RecurringAlertBannerWidget> {
  late final GetRecurringTransactions _getRecurringTransactions;

  bool _isLoading = true;
  RecurringTransactionEntity? _priorityItem;
  int _overdueCount = 0;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _getRecurringTransactions =
        RecurringTransactionsRegistry.module.getRecurringTransactions;
    _loadAlert();
  }

  @override
  void didUpdateWidget(covariant RecurringAlertBannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _dismissed = false;
      _loadAlert();
    }
  }

  Future<void> _loadAlert() async {
    try {
      final items = await _getRecurringTransactions(includeInactive: false);

      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);

      final overdue = items
          .where((item) => item.nextRunDate.isBefore(todayMidnight))
          .toList()
        ..sort((a, b) => a.nextRunDate.compareTo(b.nextRunDate));

      if (!mounted) return;

      setState(() {
        _priorityItem = overdue.isEmpty ? null : overdue.first;
        _overdueCount = overdue.length;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('RecurringAlertBannerWidget error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _priorityItem = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _dismissed || _priorityItem == null) {
      return const SizedBox.shrink();
    }

    const alertColor = AppTheme.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alertColor.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sync_problem_rounded,
              size: 16,
              color: alertColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _overdueCount == 1
                      ? 'Recurrente vencida'
                      : '$_overdueCount recurrentes vencidas',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: alertColor,
                  ),
                ),
                Text(
                  _overdueCount == 1
                      ? '"${_priorityItem!.description}" está pendiente de procesar.'
                      : '"${_priorityItem!.description}" y ${_overdueCount - 1} más pendientes.',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onManagePressed != null)
            TextButton(
              onPressed: widget.onManagePressed,
              child: const Text('Ver'),
            ),
          IconButton(
            onPressed: () => setState(() => _dismissed = true),
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppTheme.onSurfaceMuted,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}
