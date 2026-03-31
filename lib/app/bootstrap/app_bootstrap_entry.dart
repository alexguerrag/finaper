import 'package:flutter/material.dart';

import '../app.dart';
import 'app_bootstrap_controller.dart';
import 'bootstrap_error_view.dart';
import 'bootstrap_loading_view.dart';
import 'bootstrap_status.dart';

class AppBootstrapEntry extends StatefulWidget {
  const AppBootstrapEntry({super.key});

  @override
  State<AppBootstrapEntry> createState() => _AppBootstrapEntryState();
}

class _AppBootstrapEntryState extends State<AppBootstrapEntry> {
  late final AppBootstrapController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppBootstrapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
    } catch (_) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        switch (_controller.status) {
          case BootstrapStatus.idle:
          case BootstrapStatus.initializing:
            return const BootstrapLoadingView();
          case BootstrapStatus.ready:
            return const FinaperApp();
          case BootstrapStatus.failure:
            return BootstrapErrorView(
              message: _controller.errorMessage ??
                  'No se pudo inicializar la aplicación.',
              onRetry: _initialize,
            );
        }
      },
    );
  }
}
