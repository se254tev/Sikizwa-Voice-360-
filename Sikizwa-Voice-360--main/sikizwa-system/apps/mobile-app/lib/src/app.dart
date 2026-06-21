import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/settings_provider.dart';
import 'providers/app_providers.dart';
import 'theme/app_theme.dart';

class SikizwaApp extends ConsumerWidget {
  const SikizwaApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Kick off an asynchronous, non-blocking connection health check at startup.
    // This will update `connectionStatusProvider` when complete and will not block UI.
    Future<void>(() async {
      try {
        final checker = ref.read(connectionCheckServiceProvider);
        final status = await checker.checkAllConnections();
        ref.read(connectionStatusProvider.notifier).state = status;
      } catch (_) {
        // ignore errors; connectionStatusProvider remains defaults
      }
    });

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(settings.fontScale),
        highContrast: settings.highContrast,
      ),
      child: MaterialApp.router(
        title: 'Sikizwa Voice 360°',
        theme: AppTheme.forBrightness(Brightness.light, highContrast: settings.highContrast),
        darkTheme: AppTheme.forBrightness(Brightness.dark, highContrast: settings.highContrast),
        themeMode: settings.themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
