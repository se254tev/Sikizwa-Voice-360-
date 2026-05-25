import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai/presentation/ai_chat_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/pairing_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/emergency/emergency_screen.dart';
import '../features/home/home_screen.dart';
import '../features/pendant/pendant_pairing_screen.dart';
import '../features/reports/report_list_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/wellness/wellness_screen.dart';
import '../shared/widgets/app_bottom_navigation.dart';

class AppRouter {
  static GoRouter router(String initialLocation) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
        GoRoute(path: '/register', builder: (ctx, state) => const RegisterScreen()),
        GoRoute(
          path: '/pairing',
          builder: (ctx, state) => const PairingScreen(mode: PairingMode.link),
        ),
        GoRoute(
          path: '/pairing/generate',
          builder: (ctx, state) => const PairingScreen(mode: PairingMode.generate),
        ),
        GoRoute(
          path: '/pendant-pairing',
          builder: (ctx, state) => const PendantPairingScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return Scaffold(
              body: navigationShell,
              bottomNavigationBar: AppBottomNavigationBar(shell: navigationShell),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/home', builder: (ctx, state) => const HomeScreen()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/reports', builder: (ctx, state) => const ReportListScreen()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/wellness', builder: (ctx, state) => const WellnessScreen()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/emergency', builder: (ctx, state) => const EmergencyScreen()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/settings', builder: (ctx, state) => const SettingsScreen()),
              ],
            ),
          ],
        ),
        GoRoute(path: '/ai-chat', builder: (ctx, state) => const AiChatScreen()),
      ],
    );
  }
}
