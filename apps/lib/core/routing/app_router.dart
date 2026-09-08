import 'dart:io';

import 'package:farmer_mobile_app/features/auth/login_screen.dart';
import 'package:farmer_mobile_app/features/auth/register_screen.dart';
import 'package:farmer_mobile_app/features/detection/detection_screen.dart';
import 'package:farmer_mobile_app/features/detection/result_detail_screen.dart';
import 'package:farmer_mobile_app/features/detection/result_screen.dart';
import 'package:farmer_mobile_app/features/history/history_screen.dart';
import 'package:farmer_mobile_app/features/notifications/notification_screen.dart';
import 'package:farmer_mobile_app/features/profile/profile_screen.dart';
import 'package:farmer_mobile_app/features/profile/settings_screen.dart';
import 'package:farmer_mobile_app/features/splash/onboarding_screen.dart';
import 'package:farmer_mobile_app/features/tips/tips_screen.dart';
import 'package:farmer_mobile_app/features/weather/weather_screen.dart';
import 'package:farmer_mobile_app/features/splash/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/language_setup/language_screen.dart';
import '../../features/home/home_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash', // App starts here
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      // Add your Login route here later
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/detection',
        builder: (context, state) => const DetectionScreen(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final image = state.extra as File;
          return ResultScreen(image: image);
        },
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          // 1. Get the image from extra safely
          final File? image = state.extra as File?;

          // 2. If the image is null (failed to pass), go back to home instead of crashing
          if (image == null) {
            return const HomeScreen();
          }

          return ResultDetailScreen(image: image);
        },
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const DetectionScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/weather',
        builder: (context, state) => const WeatherScreen(),
      ),
      GoRoute(path: '/tips', builder: (context, state) => const TipsScreen()),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
  );
}

// Temporary Placeholder
class LoginPlaceholder extends StatelessWidget {
  const LoginPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text("Login Page")));
}
