import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/goal_model.dart';
import '../../di/goals_registry.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/usecases/create_goal.dart';
import '../../domain/usecases/delete_goal.dart';
import '../../domain/usecases/get_goals.dart';
import '../../domain/usecases/update_goal.dart';
import '../widgets/add_goal_sheet.dart';
import '../widgets/update_goal_progress_sheet.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late final GetGoals _getGoals;
  late final CreateGoal _createGoal;
  late final UpdateGoal _updateGoal;
  late final DeleteGoal _deleteGoal;

  bool _isLoading = true;
  _GoalFilter _filter = _GoalFilter.active;
  List<GoalEntity> _goals = <GoalEntity>[];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getGoals = GoalsRegistry.module.getGoals;
    _createGoal = GoalsRegistry.module.createGoal;
    _updateGoal = GoalsRegistry.module.updateGoal;
    _deleteGoal = GoalsRegistry.module.deleteGoal;
    _loadGoals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await _getGoals(includeCompleted: true);

      if (!mounted) return;

      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('GoalsScreen load error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron cargar las metas.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _openAddGoalSheet() async {
    final result = await showModalBottomSheet<GoalModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddGoalSheet(),
    );

    if (result == null) return;

    try {
      await _createGoal(result);
      await _loadGoals();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Meta creada correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Create goal error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo crear la meta.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _openEditGoalSheet(GoalEntity goal) async {
    final result = await showModalBottomSheet<GoalModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddGoalSheet(initialGoal: goal),
    );

    if (result == null) return;

    try {
      await _updateGoal(result);
      await _loadGoals();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Meta actualizada correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Update goal error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo actualizar la meta.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _openUpdateProgressSheet(GoalEntity goal) async {
    final result = await showModalBottomSheet<GoalModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateGoalProgressSheet(goal: goal),
    );

    if (result == null) return;

    try {
      await _updateGoal(result);
      await _loadGoals();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Progreso actualizado correctamente.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Update goal error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo actualizar la meta.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteGoal(GoalEntity goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: Text(
          'Eliminar meta',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
          ),
        ),
        content: Text(
          '¿Seguro que quieres eliminar "${goal.name}"? Esta acción no se puede deshacer.',
          style: GoogleFonts.manrope(color: AppTheme.onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: GoogleFonts.manrope()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.expense,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _deleteGoal(goal.id);
      await _loadGoals();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Meta eliminada.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('Delete goal error: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar la meta.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  List<GoalEntity> get _filteredGoals {
    final List<GoalEntity> byStatus;
    switch (_filter) {
      case _GoalFilter.active:
        byStatus = _goals.where((goal) => !goal.isCompleted).toList();
      case _GoalFilter.completed:
        byStatus = _goals.where((goal) => goal.isCompleted).toList();
      case _GoalFilter.all:
        byStatus = _goals;
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return byStatus;
    return byStatus
        .where((g) => g.name.toLowerCase().contains(q))
        .toList();
  }

  String _dateSubtitle(GoalEntity goal) {
    if (goal.targetDate == null) {
      return 'Sin fecha objetivo';
    }

    return 'Meta para ${AppFormatters.formatShortDate(goal.targetDate!)}';
  }

  String _progressAmountsLabel(GoalEntity goal) {
    final current = AppFormatters.formatCurrency(goal.currentAmount);
    final target = AppFormatters.formatCurrency(goal.targetAmount);
    return '$current / $target';
  }

  @override
  Widget build(BuildContext context) {
    final goals = _filteredGoals;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Metas',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddGoalSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadGoals,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Gestiona tus objetivos de ahorro y monitorea su progreso.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _GoalFilterChip(
                  label: 'Activas',
                  selected: _filter == _GoalFilter.active,
                  onTap: () {
                    setState(() {
                      _filter = _GoalFilter.active;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _GoalFilterChip(
                  label: 'Completadas',
                  selected: _filter == _GoalFilter.completed,
                  onTap: () {
                    setState(() {
                      _filter = _GoalFilter.completed;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _GoalFilterChip(
                  label: 'Todas',
                  selected: _filter == _GoalFilter.all,
                  onTap: () {
                    setState(() {
                      _filter = _GoalFilter.all;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Limpiar búsqueda',
                      ),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (goals.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 36,
                      color: AppTheme.onSurfaceMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Todavía no hay metas en este filtro.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Crea una meta para comenzar a seguir tus objetivos.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppTheme.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...goals.map(
                (goal) {
                  final progress = goal.progress;
                  final accentColor =
                      goal.isCompleted ? AppTheme.income : goal.color;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                IconData(
                                  goal.iconCode,
                                  fontFamily: 'MaterialIcons',
                                ),
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          goal.name,
                                          style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      if (goal.isCompleted)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.income.withValues(
                                              alpha: 0.14,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'Completada',
                                            style: GoogleFonts.manrope(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.income,
                                            ),
                                          ),
                                        ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.more_vert_rounded,
                                          size: 18,
                                          color: AppTheme.onSurfaceMuted,
                                        ),
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _openEditGoalSheet(goal);
                                          } else if (value == 'delete') {
                                            _confirmDeleteGoal(goal);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                  color: AppTheme.onSurface,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Editar',
                                                  style: GoogleFonts.manrope(
                                                    color: AppTheme.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: AppTheme.expense,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Eliminar',
                                                  style: GoogleFonts.manrope(
                                                    color: AppTheme.expense,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dateSubtitle(goal),
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: AppTheme.onSurfaceMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: progress,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.08),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _progressAmountsLabel(goal),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppTheme.onSurfaceMuted,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _openUpdateProgressSheet(goal);
                            },
                            icon: Icon(
                              goal.isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.trending_up_rounded,
                            ),
                            label: Text(
                              goal.isCompleted
                                  ? 'Actualizar avance'
                                  : 'Registrar avance',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.onSurface,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

enum _GoalFilter {
  active,
  completed,
  all,
}

class _GoalFilterChip extends StatelessWidget {
  const _GoalFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.onSurface,
          ),
        ),
      ),
    );
  }
}
