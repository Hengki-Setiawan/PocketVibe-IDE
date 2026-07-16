import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../views/onboarding/onboarding_screen.dart';
import '../../views/onboarding/installation_guide_screen.dart';
import '../../views/onboarding/setup_progress_screen.dart';
import '../../views/dashboard/dashboard_screen.dart';
import '../../views/workspace/workspace_screen.dart';
import '../../views/settings/settings_screen.dart';
import '../../views/settings/provider_keys_screen.dart';
import '../../views/settings/about_screen.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halaman Tidak Ditemukan')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Halaman tidak ditemukan', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Kembali ke Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    errorBuilder: (_, __) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/setup/guide',
        name: 'setupGuide',
        builder: (_, __) => const InstallationGuideScreen(),
      ),
      GoRoute(
        path: '/setup/progress',
        name: 'setupProgress',
        builder: (_, __) => const SetupProgressScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/workspace/:projectId',
        name: 'workspace',
        builder: (_, state) => WorkspaceScreen(
          projectId: state.pathParameters['projectId']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'keys',
            name: 'providerKeys',
            builder: (_, __) => const ProviderKeysScreen(),
          ),
          GoRoute(
            path: 'about',
            name: 'about',
            builder: (_, __) => const AboutScreen(),
          ),
        ],
      ),
    ],
  );
}
