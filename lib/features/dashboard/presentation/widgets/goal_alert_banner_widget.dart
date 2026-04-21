import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../goals/di/goals_registry.dart';
import '../../../goals/domain/entities/goal_entity.dart';
import '../../../goals/domain/usecases/get_goals.dart';

class GoalAlertBannerWidget extends StatefulWidget {
  const GoalAlertBannerWidget({
    super.key,
    required this.refreshToken,
    this.onManagePressed,
    this.deadlineThresholdDays = 30,
  });

  final int refreshToken;
  final VoidCallback? onManagePressed;
  final int deadlineThresholdDays;

  @override
  State<GoalAlertBannerWidget> createState() => _GoalAlertBannerWidgetState();
}

class _GoalAlertBannerWidgetState extends State<GoalAlertBannerWidget> {
  late final GetGoals _getGoals;

  bool _isLoading = true;
  GoalEntity? _priorityGoal;
  int _atRiskCount = 0;
  int _priorityDaysLeft = 0;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _getGoals = GoalsRegistry.module.getGoals;
    _loadAlert();
  }

  @override
  void didUpdateWidget(covariant GoalAlertBannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _dismissed = false;
      _loadAlert();
    }
  }

  Future<void> _loadAlert() async {
    try {
      final goals = await _getGoals(includeCompleted: false);

      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);

      final atRisk = goals.where((g) {
        if (g.targetDate == null) return false;
        final daysLeft =
            g.targetDate!.difference(todayMidnight).inDays;
        return daysLeft >= 0 && daysLeft <= widget.deadlineThresholdDays;
      }).toList()
        ..sort((a, b) => a.targetDate!.compareTo(b.targetDate!));

      if (!mounted) return;

      int daysLeft = 0;
      if (atRisk.isNotEmpty) {
        daysLeft =
            atRisk.first.targetDate!.difference(todayMidnight).inDays;
      }

      setState(() {
        _priorityGoal = atRisk.isEmpty ? null : atRisk.first;
        _atRiskCount = atRisk.length;
        _priorityDaysLeft = daysLeft;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('GoalAlertBannerWidget error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _priorityGoal = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _dismissed || _priorityGoal == null) {
      return const SizedBox.shrink();
    }

    final isUrgent = _priorityDaysLeft <= 7;
    final alertColor = isUrgent ? AppTheme.expense : AppTheme.warning;

    final daysLabel = _priorityDaysLeft == 0
        ? 'vence hoy'
        : _priorityDaysLeft == 1
            ? 'vence mañana'
            : 'vence en $_priorityDaysLeft días';

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
            child: Icon(
              isUrgent ? Icons.flag_rounded : Icons.timer_outlined,
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
                  _atRiskCount == 1
                      ? 'Meta próxima a vencer'
                      : '$_atRiskCount metas próximas a vencer',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: alertColor,
                  ),
                ),
                Text(
                  _atRiskCount == 1
                      ? '"${_priorityGoal!.name}" $daysLabel.'
                      : '"${_priorityGoal!.name}" $daysLabel y ${_atRiskCount - 1} más.',
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
