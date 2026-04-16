import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/enums/category_kind.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/category_model.dart';
import '../../domain/entities/category_entity.dart';

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({
    super.key,
    required this.initialKind,
    this.initialCategory,
  });

  final CategoryKind initialKind;
  final CategoryEntity? initialCategory;

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  late CategoryKind _selectedKind;

  bool get _isEditing => widget.initialCategory != null;

  @override
  void initState() {
    super.initState();
    _selectedKind = widget.initialCategory?.kind ?? widget.initialKind;

    if (widget.initialCategory != null) {
      _nameController.text = widget.initialCategory!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  IconData _iconForKind(CategoryKind kind) {
    switch (kind) {
      case CategoryKind.expense:
        return Icons.local_offer_rounded;
      case CategoryKind.income:
        return Icons.attach_money_rounded;
    }
  }

  Color _colorForKind(CategoryKind kind) {
    switch (kind) {
      case CategoryKind.expense:
        return Colors.deepOrange;
      case CategoryKind.income:
        return Colors.green;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final initial = widget.initialCategory;

    final category = CategoryModel(
      id: initial != null
          ? initial.id
          : 'cat-${_selectedKind.value}-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      kind: _selectedKind,
      iconCode: initial != null
          ? initial.iconCode
          : _iconForKind(_selectedKind).codePoint,
      color: initial != null
          ? initial.color.withValues(alpha: 1.0)
          : _colorForKind(_selectedKind).withValues(alpha: 1.0),
      isSystem: false,
      createdAt: initial != null ? initial.createdAt : DateTime.now(),
    );

    Navigator.of(context).pop(category);
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
                    _isEditing ? 'Editar categoría' : 'Nueva categoría',
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
                      hintText: 'Ej. Mascotas, Viajes, Bonos',
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
                  DropdownButtonFormField<CategoryKind>(
                    initialValue: _selectedKind,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                    ),
                    // kind is locked in edit mode to avoid breaking budget
                    // coherence and historical transaction classification
                    onChanged: _isEditing
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedKind = value;
                            });
                          },
                    items: CategoryKind.values
                        .map(
                          (kind) => DropdownMenuItem<CategoryKind>(
                            value: kind,
                            child: Text(kind.label),
                          ),
                        )
                        .toList(),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 8),
                    Text(
                      'El tipo no se puede cambiar en categorías existentes.',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppTheme.onSurfaceMuted,
                      ),
                    ),
                  ],
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
                        _isEditing ? 'Guardar cambios' : 'Guardar categoría',
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
