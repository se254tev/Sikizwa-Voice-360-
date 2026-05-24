import 'package:go_router/go_router.dart';
import '../../features/ai/presentation/ai_chat_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/pairing_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/admin_login_screen.dart';
import '../features/auth/admin_signup_screen.dart';
import '../features/auth/admin_home_screen.dart';
import '../features/home/home_screen.dart';
import '../features/reports/report_list_screen.dart';
import '../features/emergency/emergency_screen.dart';
import '../features/wellness/wellness_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRouter {
  static GoRouter router(String initialLocation) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
        GoRoute(path: '/register', builder: (ctx, state) => const RegisterScreen()),
        GoRoute(path: '/admin/login', builder: (ctx, state) => const AdminLoginScreen()),
        GoRoute(path: '/admin/signup', builder: (ctx, state) => const AdminSignupScreen()),
        GoRoute(path: '/admin/dashboard', builder: (ctx, state) => const AdminHomeScreen()),
        GoRoute(
          path: '/pairing',
          builder: (ctx, state) => const PairingScreen(mode: PairingMode.link),
        ),
        GoRoute(
          path: '/pairing/generate',
          builder: (ctx, state) => const PairingScreen(mode: PairingMode.generate),
        ),
        GoRoute(path: '/home', builder: (ctx, state) => const HomeScreen()),
        GoRoute(path: '/reports', builder: (ctx, state) => const ReportListScreen()),
        GoRoute(path: '/emergency', builder: (ctx, state) => const EmergencyScreen()),
        GoRoute(path: '/wellness', builder: (ctx, state) => const WellnessScreen()),
        GoRoute(path: '/settings', builder: (ctx, state) => const SettingsScreen()),
        GoRoute(path: '/ai-chat', builder: (ctx, state) => const AiChatScreen()),
      ],
    );
  }
}
