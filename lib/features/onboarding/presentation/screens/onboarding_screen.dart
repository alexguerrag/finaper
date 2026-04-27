import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/settings/di/settings_registry.dart';
import '../../../../features/settings/domain/entities/app_settings_entity.dart';
import '../../../../features/settings/presentation/controllers/settings_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final SettingsController _controller;

  String _selectedCurrency = AppSettingsEntity.defaultCurrencyCode;
  String _selectedLocale = AppSettingsEntity.defaultLocaleCode;
  bool _useSystemLocale = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = SettingsRegistry.module.controller;

    // Pre-fill with current persisted settings (in case of partial save)
    final s = _controller.currentSettings;
    _selectedCurrency = s.currencyCode;
    _selectedLocale = s.localeCode;
    _useSystemLocale = s.useSystemLocale;
  }

  Future<void> _complete() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final ok = await _controller.saveGeneralSettings(
      currencyCode: _selectedCurrency,
      localeCode: _selectedLocale,
      useSystemLocale: _useSystemLocale,
      hasCompletedOnboarding: true,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la configuración. Intenta de nuevo.',
            style: GoogleFonts.manrope(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Icon
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 36,
                    color: AppTheme.primary,
                  ),
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppTheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Header
              Text(
                'Bienvenido a Finaper',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Empieza a controlar tu dinero',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: AppTheme.onSurfaceMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Hint card
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 20,
                      color: AppTheme.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Después podrás crear tu primera cuenta',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ej. Banco, Efectivo o Tarjeta',
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
              ),
              const SizedBox(height: 32),

              // Currency
              const _SectionLabel(label: 'Selecciona tu moneda'),
              const SizedBox(height: 8),
              _DropdownCard<String>(
                value: _selectedCurrency,
                items: SettingsController.supportedCurrencies
                    .map(
                        (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCurrency = v);
                },
              ),
              const SizedBox(height: 24),

              // Locale
              const _SectionLabel(label: 'Selecciona tu idioma'),
              const SizedBox(height: 8),
              _DropdownCard<String>(
                value: _useSystemLocale ? null : _selectedLocale,
                hint: _useSystemLocale ? 'Usando región del sistema' : null,
                enabled: !_useSystemLocale,
                items: SettingsController.supportedLocaleOptions
                    .map(
                        (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedLocale = v);
                },
              ),
              const SizedBox(height: 12),
              _SystemLocaleToggle(
                value: _useSystemLocale,
                onChanged: (v) => setState(() => _useSystemLocale = v),
              ),
              const SizedBox(height: 48),

              // CTA
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _complete,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded, size: 20),
                  iconAlignment: IconAlignment.end,
                  label: Text(
                    'Continuar',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.onSurfaceMuted,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _DropdownCard<T> extends StatelessWidget {
  const _DropdownCard({
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.enabled = true,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint != null
              ? Text(
                  hint!,
                  style: GoogleFonts.manrope(
                    color: AppTheme.onSurfaceMuted,
                    fontSize: 14,
                  ),
                )
              : null,
          isExpanded: true,
          dropdownColor: AppTheme.surfaceElevated,
          style: GoogleFonts.manrope(
            color: AppTheme.onSurface,
            fontSize: 14,
          ),
          iconEnabledColor: AppTheme.onSurfaceMuted,
          iconDisabledColor: AppTheme.onSurfaceMuted,
          items: enabled ? items : [],
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

class _SystemLocaleToggle extends StatelessWidget {
  const _SystemLocaleToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Usar región del sistema operativo',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
