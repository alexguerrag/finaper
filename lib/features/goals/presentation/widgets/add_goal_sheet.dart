import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/goal_model.dart';
import '../../domain/entities/goal_entity.dart';

class AddGoalSheet extends StatefulWidget {
  const AddGoalSheet({
    super.key,
    this.initialGoal,
  });

  final GoalEntity? initialGoal;

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _currentAmountController = TextEditingController(
    text: '0',
  );

  DateTime? _targetDate;
  late _GoalVisualPreset _selectedPreset;

  static final List<_GoalVisualPreset> _presets = [
    const _GoalVisualPreset(
      label: 'Ahorro',
      icon: Icons.savings_rounded,
      color: Colors.green,
    ),
    const _GoalVisualPreset(
      label: 'Viaje',
      icon: Icons.flight_takeoff_rounded,
      color: Colors.blue,
    ),
    const _GoalVisualPreset(
      label: 'Casa',
      icon: Icons.home_rounded,
      color: Colors.orange,
    ),
    const _GoalVisualPreset(
      label: 'Auto',
      icon: Icons.directions_car_rounded,
      color: Colors.indigo,
    ),
    const _GoalVisualPreset(
      label: 'Emergencia',
      icon: Icons.health_and_safety_rounded,
      color: Colors.red,
    ),
    const _GoalVisualPreset(
      label: 'General',
      icon: Icons.flag_rounded,
      color: Colors.purple,
    ),
  ];

  bool get _isEditing => widget.initialGoal != null;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialGoal;

    if (initial != null) {
      _nameController.text = initial.name;
      _targetAmountController.text = initial.targetAmount.toString();
      _currentAmountController.text = initial.currentAmount.toString();
      _targetDate = initial.targetDate;
      _selectedPreset = _presets.firstWhere(
        (p) => p.icon.codePoint == initial.iconCode,
        orElse: () => _presets.first,
      );
    } else {
      _selectedPreset = _presets.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: _targetDate ?? DateTime.now(),
        firstDate: DateTime(2024),
        lastDate: DateTime(2040),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppTheme.primary,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (picked == null) return;

      setState(() {
        _targetDate = picked;
      });
    } catch (e) {
      debugPrint('Goal date picker error: $e');
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final normalizedTarget =
        _targetAmountController.text.trim().replaceAll(',', '.');
    final normalizedCurrent =
        _currentAmountController.text.trim().replaceAll(',', '.');

    final targetAmount = double.parse(normalizedTarget);
    final currentAmount = double.parse(normalizedCurrent);

    final now = DateTime.now();
    final isCompleted = currentAmount >= targetAmount;

    final initial = widget.initialGoal;

    final goal = GoalModel(
      id: initial != null ? initial.id : 'goal-${now.millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: _targetDate,
      color: _selectedPreset.color.withValues(alpha: 1.0),
      iconCode: _selectedPreset.icon.codePoint,
      isCompleted: isCompleted,
      createdAt: initial != null ? initial.createdAt : now,
      updatedAt: now,
    );

    Navigator.of(context).pop(goal);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isEditing ? 'Editar meta' : 'Nueva meta',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej. Fondo de emergencia',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un nombre';
                      }
                      if (value.trim().length < 3) {
                        return 'Debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<_GoalVisualPreset>(
                    initialValue: _selectedPreset,
                    decoration: const InputDecoration(
                      labelText: 'Tipo visual',
                    ),
                    items: _presets
                        .map(
                          (preset) => DropdownMenuItem<_GoalVisualPreset>(
                            value: preset,
                            child: Row(
                              children: [
                                Icon(
                                  preset.icon,
                                  color: preset.color,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(preset.label),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedPreset = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _targetAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monto objetivo',
                      hintText: 'Ej. 5000',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un monto objetivo';
                      }

                      final normalized = value.trim().replaceAll(',', '.');
                      final parsed = double.tryParse(normalized);

                      if (parsed == null) {
                        return 'Monto inválido';
                      }

                      if (parsed <= 0) {
                        return 'Debe ser mayor a cero';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currentAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monto acumulado inicial',
                      hintText: 'Ej. 0',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un monto inicial';
                      }

                      final normalized = value.trim().replaceAll(',', '.');
                      final parsed = double.tryParse(normalized);

                      if (parsed == null) {
                        return 'Monto inválido';
                      }

                      if (parsed < 0) {
                        return 'No puede ser negativo';
                      }

                      final target = double.tryParse(
                        _targetAmountController.text
                            .trim()
                            .replaceAll(',', '.'),
                      );

                      if (target != null && parsed > target) {
                        return 'No debe superar el objetivo';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickTargetDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _targetDate == null
                                  ? 'Fecha objetivo (opcional)'
                                  : 'Fecha objetivo: ${_formatDate(_targetDate!)}',
                              style: GoogleFonts.manrope(
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ),
                          if (_targetDate != null)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _targetDate = null;
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                          else
                            const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Guardar cambios' : 'Guardar meta',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalVisualPreset {
  const _GoalVisualPreset({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
