import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import '../core/config/supported_locales.dart';
import '../core/theme/app_theme.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/settings/di/settings_registry.dart';
import '../features/settings/presentation/controllers/settings_controller.dart';
import '../features/shell/presentation/pages/main_shell_page.dart';
import 'bootstrap/app_bootstrap_controller.dart';
import 'bootstrap/bootstrap_error_view.dart';
import 'bootstrap/bootstrap_loading_view.dart';
import 'bootstrap/bootstrap_status.dart';
import 'routes/app_routes.dart';

class FinaperApp extends StatefulWidget {
  const FinaperApp({super.key});

  @override
  State<FinaperApp> createState() => _FinaperAppState();
}

class _FinaperAppState extends State<FinaperApp> {
  late final AppBootstrapController _bootstrap;
  SettingsController? _settings;

  @override
  void initState() {
    super.initState();
    _bootstrap = AppBootstrapController();
    _bootstrap.addListener(_onBootstrapChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    try {
      await _bootstrap.initialize();
    } catch (_) {
      // Error stored in _bootstrap.errorMessage; _onBootstrapChanged drives the rebuild.
    }
  }

  void _onBootstrapChanged() {
    if (_bootstrap.isReady && _settings == null) {
      final sc = SettingsRegistry.module.controller;
      sc.addListener(_onSettingsChanged);
      setState(() => _settings = sc);
      return;
    }
    if (mounted) setState(() {});
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _bootstrap.removeListener(_onBootstrapChanged);
    _settings?.removeListener(_onSettingsChanged);
    _bootstrap.dispose();
    super.dispose();
  }

  Widget _buildHome() {
    switch (_bootstrap.status) {
      case BootstrapStatus.idle:
      case BootstrapStatus.initializing:
        return const BootstrapLoadingView();
      case BootstrapStatus.failure:
        return BootstrapErrorView(
          message: _bootstrap.errorMessage ?? 'No se pudo inicializar la aplicación.',
          onRetry: _initialize,
        );
      case BootstrapStatus.ready:
        final sc = _settings;
        if (sc == null) return const BootstrapLoadingView();
        return sc.hasCompletedOnboarding
            ? const MainShellPage()
            : const OnboardingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _settings;
    if (sc != null) {
      Intl.defaultLocale = sc.resolvedLocaleCode;
    }

    return MaterialApp(
      title: 'Finaper',
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'finaper_app',
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      locale: sc?.materialAppLocale,
      supportedLocales: AppSupportedLocales.all,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _buildHome(),
      routes: AppRoutes.namedRoutes,
    );
  }
}
