import 'package:flutter/material.dart';

import 'navigation/app_router.dart';
import 'theme/app_theme.dart';

class SikizwaApp extends StatelessWidget {
  const SikizwaApp({super.key, required this.initialLocation});

  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sikizwa Voice 360°',
      theme: AppTheme.light,
      routerConfig: AppRouter.router(initialLocation),
      debugShowCheckedModeBanner: false,
    );
  }
}
