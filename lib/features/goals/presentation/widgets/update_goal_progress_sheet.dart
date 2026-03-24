import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/goal_model.dart';
import '../../domain/entities/goal_entity.dart';

class UpdateGoalProgressSheet extends StatefulWidget {
  const UpdateGoalProgressSheet({
    super.key,
    required this.goal,
  });

  final GoalEntity goal;

  @override
  State<UpdateGoalProgressSheet> createState() =>
      _UpdateGoalProgressSheetState();
}

class _UpdateGoalProgressSheetState extends State<UpdateGoalProgressSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _incrementController = TextEditingController();

  @override
  void dispose() {
    _incrementController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final normalized = _incrementController.text.trim().replaceAll(',', '.');
    final incrementAmount = double.parse(normalized);

    final nextAmount = widget.goal.currentAmount + incrementAmount;
    final cappedAmount = nextAmount > widget.goal.targetAmount
        ? widget.goal.targetAmount
        : nextAmount;

    final isCompleted = cappedAmount >= widget.goal.targetAmount;
    final now = DateTime.now();

    final updatedGoal = GoalModel(
      id: widget.goal.id,
      name: widget.goal.name,
      targetAmount: widget.goal.targetAmount,
      currentAmount: cappedAmount,
      targetDate: widget.goal.targetDate,
      color: widget.goal.color.withValues(alpha: 1.0),
      iconCode: widget.goal.iconCode,
      isCompleted: isCompleted,
      createdAt: widget.goal.createdAt,
      updatedAt: now,
    );

    Navigator.of(context).pop(updatedGoal);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final remainingAmount =
        (widget.goal.targetAmount - widget.goal.currentAmount) < 0
            ? 0.0
            : (widget.goal.targetAmount - widget.goal.currentAmount);

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
                    'Registrar avance',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.goal.name,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Objetivo: \$${widget.goal.targetAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Acumulado actual: \$${widget.goal.currentAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pendiente: \$${remainingAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _incrementController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monto a sumar',
                      hintText: 'Ej. 50',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un monto';
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
                    onChanged: (value) {
                      final normalized = value.replaceAll(',', '.');
                      if (normalized != value) {
                        _incrementController.value =
                            _incrementController.value.copyWith(
                          text: normalized,
                          selection: TextSelection.collapsed(
                            offset: normalized.length,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Este valor se sumará al acumulado actual.',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppTheme.onSurfaceMuted,
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
                        'Guardar avance',
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
