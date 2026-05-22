import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'navigation/app_router.dart';
import 'theme/app_theme.dart';

class SikizwaApp extends StatelessWidget {
  const SikizwaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sikizwa Voice 360°',
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
