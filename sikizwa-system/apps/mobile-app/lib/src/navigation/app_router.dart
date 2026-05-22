import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/reports/report_list_screen.dart';
import '../features/emergency/emergency_screen.dart';
import '../features/wellness/wellness_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (ctx, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (ctx, state) => const HomeScreen()),
      GoRoute(path: '/reports', builder: (ctx, state) => const ReportListScreen()),
      GoRoute(path: '/emergency', builder: (ctx, state) => const EmergencyScreen()),
      GoRoute(path: '/wellness', builder: (ctx, state) => const WellnessScreen()),
      GoRoute(path: '/settings', builder: (ctx, state) => const SettingsScreen()),
    ],
  );
}
