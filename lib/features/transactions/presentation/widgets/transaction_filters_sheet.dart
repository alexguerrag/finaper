import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

enum TransactionDateFilterOption {
  all,
  last7Days,
  last30Days,
  thisMonth,
  custom,
}

enum TransactionSortOption {
  newestFirst,
  oldestFirst,
  highestAmount,
  lowestAmount,
}

class TransactionListFilterState {
  const TransactionListFilterState({
    required this.dateFilter,
    required this.sortOption,
    this.customRange,
  });

  final TransactionDateFilterOption dateFilter;
  final TransactionSortOption sortOption;
  final DateTimeRange? customRange;

  TransactionListFilterState copyWith({
    TransactionDateFilterOption? dateFilter,
    TransactionSortOption? sortOption,
    DateTimeRange? customRange,
    bool clearCustomRange = false,
  }) {
    return TransactionListFilterState(
      dateFilter: dateFilter ?? this.dateFilter,
      sortOption: sortOption ?? this.sortOption,
      customRange: clearCustomRange ? null : (customRange ?? this.customRange),
    );
  }
}

class TransactionFiltersSheet extends StatefulWidget {
  const TransactionFiltersSheet({
    super.key,
    required this.initialState,
    required this.onApply,
  });

  final TransactionListFilterState initialState;
  final ValueChanged<TransactionListFilterState> onApply;

  @override
  State<TransactionFiltersSheet> createState() =>
      _TransactionFiltersSheetState();
}

class _TransactionFiltersSheetState extends State<TransactionFiltersSheet> {
  late TransactionListFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialRange = _state.customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day).subtract(
            const Duration(days: 7),
          ),
          end: DateTime(now.year, now.month, now.day),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
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
      _state = _state.copyWith(
        dateFilter: TransactionDateFilterOption.custom,
        customRange: picked,
      );
    });
  }

  String _dateFilterLabel(TransactionDateFilterOption option) {
    switch (option) {
      case TransactionDateFilterOption.all:
        return 'Todo';
      case TransactionDateFilterOption.last7Days:
        return '7 días';
      case TransactionDateFilterOption.last30Days:
        return '30 días';
      case TransactionDateFilterOption.thisMonth:
        return 'Este mes';
      case TransactionDateFilterOption.custom:
        return 'Personalizado';
    }
  }

  String _sortLabel(TransactionSortOption option) {
    switch (option) {
      case TransactionSortOption.newestFirst:
        return 'Más recientes';
      case TransactionSortOption.oldestFirst:
        return 'Más antiguas';
      case TransactionSortOption.highestAmount:
        return 'Mayor monto';
      case TransactionSortOption.lowestAmount:
        return 'Menor monto';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                'Filtrar y ordenar',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ajusta el período visible y el orden de la lista.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Período',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TransactionDateFilterOption.values.map((option) {
                  return _FilterChoiceChip(
                    label: _dateFilterLabel(option),
                    selected: _state.dateFilter == option,
                    onTap: () {
                      if (option == TransactionDateFilterOption.custom) {
                        _pickCustomRange();
                        return;
                      }

                      setState(() {
                        _state = _state.copyWith(
                          dateFilter: option,
                          clearCustomRange: option !=
                              TransactionDateFilterOption.custom,
                        );
                      });
                    },
                  );
                }).toList(),
              ),
              if (_state.dateFilter == TransactionDateFilterOption.custom &&
                  _state.customRange != null) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _pickCustomRange,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    '${_state.customRange!.start.day}/${_state.customRange!.start.month}/${_state.customRange!.start.year} - ${_state.customRange!.end.day}/${_state.customRange!.end.month}/${_state.customRange!.end.year}',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'Orden',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              ...TransactionSortOption.values.map(
                (option) => RadioListTile<TransactionSortOption>(
                  value: option,
                  groupValue: _state.sortOption,
                  activeColor: AppTheme.primary,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _sortLabel(option),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _state = _state.copyWith(sortOption: value);
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _state = const TransactionListFilterState(
                            dateFilter: TransactionDateFilterOption.all,
                            sortOption: TransactionSortOption.newestFirst,
                          );
                        });
                      },
                      child: Text(
                        'Restablecer',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        widget.onApply(_state);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Aplicar',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.70)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}
