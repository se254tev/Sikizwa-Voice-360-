import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/settings_provider.dart';
import 'theme/app_theme.dart';

class SikizwaApp extends ConsumerWidget {
  const SikizwaApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

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
