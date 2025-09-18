import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/call_screen.dart';
import '../screens/contacts_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/analysis_history_screen.dart';
import '../screens/recording_control_screen.dart';
import '../screens/permission_setup_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/permission-setup',
        name: 'permission-setup',
        builder: (context, state) => const PermissionSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/call',
        name: 'call',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CallScreen(
            contactName: extra?['contactName'] ?? 'Unknown',
            phoneNumber: extra?['phoneNumber'] ?? '',
            isIncoming: extra?['isIncoming'] ?? true,
          );
        },
      ),
      GoRoute(
        path: '/contacts',
        name: 'contacts',
        builder: (context, state) => const ContactsScreen(),
      ),
      GoRoute(
        path: '/analysis-history',
        name: 'analysis-history',
        builder: (context, state) => const AnalysisHistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/recording-control',
        name: 'recording-control',
        builder: (context, state) => const RecordingControlScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}