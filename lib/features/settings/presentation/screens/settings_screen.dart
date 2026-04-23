import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/formatters/app_formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../di/settings_registry.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController _controller = SettingsRegistry.module.controller;

  static final List<_OptionItem> _currencyOptions = SettingsController
      .supportedCurrencies
      .map((e) => _OptionItem(e.$1, e.$2))
      .toList();

  static final List<_OptionItem> _localeOptions = SettingsController
      .supportedLocaleOptions
      .map((e) => _OptionItem(e.$1, e.$2))
      .toList();

  late String _selectedCurrencyCode;
  late String _selectedLocaleCode;
  late bool _useSystemLocale;

  @override
  void initState() {
    super.initState();
    _hydrateDraftFromController();
  }

  void _hydrateDraftFromController() {
    final settings = _controller.currentSettings;
    _selectedCurrencyCode = settings.currencyCode;
    _selectedLocaleCode = settings.localeCode;
    _useSystemLocale = settings.useSystemLocale;
  }

  String get _effectiveLocaleCode {
    if (_useSystemLocale) return _controller.resolvedLocaleCode;
    return _selectedLocaleCode;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final success = await _controller.saveGeneralSettings(
      currencyCode: _selectedCurrencyCode,
      localeCode: _selectedLocaleCode,
      useSystemLocale: _useSystemLocale,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Preferencias guardadas correctamente.'
              : (_controller.errorMessage ??
                  'No se pudieron guardar las preferencias.'),
        ),
      ),
    );
  }

  void _resetDraft() {
    setState(() {
      _hydrateDraftFromController();
    });
  }

  String _labelFor(List<_OptionItem> options, String value) {
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(
              'Ajustes',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                onPressed: _resetDraft,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Restablecer cambios',
              ),
            ],
          ),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SectionCard(
                      title: 'Preferencias generales',
                      subtitle:
                          'Define moneda base y formato regional para la aplicación.',
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            key: ValueKey('currency_$_selectedCurrencyCode'),
                            initialValue: _selectedCurrencyCode,
                            decoration: const InputDecoration(
                              labelText: 'Moneda base',
                            ),
                            items: _currencyOptions
                                .map(
                                  (option) => DropdownMenuItem<String>(
                                    value: option.value,
                                    child: Text(option.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedCurrencyCode = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: SwitchListTile.adaptive(
                              value: _useSystemLocale,
                              onChanged: (value) {
                                setState(() => _useSystemLocale = value);
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: const Text('Usar formato del sistema'),
                              subtitle: Text(
                                _useSystemLocale
                                    ? 'Activo ahora: ${_controller.resolvedLocaleCode}'
                                    : 'Usar selección manual',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            key: ValueKey(
                              'locale_$_selectedLocaleCode$_useSystemLocale',
                            ),
                            initialValue: _selectedLocaleCode,
                            decoration: const InputDecoration(
                              labelText: 'Formato regional',
                            ),
                            items: _localeOptions
                                .map(
                                  (option) => DropdownMenuItem<String>(
                                    value: option.value,
                                    child: Text(option.label),
                                  ),
                                )
                                .toList(),
                            onChanged: _useSystemLocale
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() => _selectedLocaleCode = value);
                                  },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Vista previa',
                      subtitle:
                          'Así se verán montos y fechas con la configuración actual.',
                      child: Column(
                        children: [
                          _PreviewRow(
                            label: 'Moneda',
                            value: _labelFor(
                              _currencyOptions,
                              _selectedCurrencyCode,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PreviewRow(
                            label: 'Formato regional',
                            value: _useSystemLocale
                                ? 'Sistema (${_controller.resolvedLocaleCode})'
                                : _labelFor(
                                    _localeOptions,
                                    _selectedLocaleCode,
                                  ),
                          ),
                          const SizedBox(height: 12),
                          _PreviewRow(
                            label: 'Monto ejemplo',
                            value: AppFormatters.formatCurrencyWith(
                              value: 123456.78,
                              currencyCode: _selectedCurrencyCode,
                              localeCode: _effectiveLocaleCode,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PreviewRow(
                            label: 'Fecha ejemplo',
                            value: AppFormatters.formatShortDateWith(
                              value: DateTime.now(),
                              localeCode: _effectiveLocaleCode,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _controller.isSaving ? null : _save,
                      icon: _controller.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _controller.isSaving
                            ? 'Guardando...'
                            : 'Guardar preferencias',
                      ),
                    ),
                    if (_controller.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _controller.errorMessage!,
                        style: GoogleFonts.manrope(
                          color: AppTheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppTheme.onSurfaceMuted,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionItem {
  const _OptionItem(this.value, this.label);

  final String value;
  final String label;
}
