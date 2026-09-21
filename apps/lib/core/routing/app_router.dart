import 'dart:io';

import 'package:farmer_mobile_app/features/auth/login_screen.dart';
import 'package:farmer_mobile_app/features/auth/register_screen.dart';
import 'package:farmer_mobile_app/features/detection/detection_screen.dart';
import 'package:farmer_mobile_app/features/detection/result_detail_screen.dart';
import 'package:farmer_mobile_app/features/detection/result_screen.dart';
import 'package:farmer_mobile_app/features/history/history_screen.dart';
import 'package:farmer_mobile_app/features/home/community_screen.dart';
import 'package:farmer_mobile_app/features/home/expert_screen.dart';
import 'package:farmer_mobile_app/features/home/market_screen.dart';
import 'package:farmer_mobile_app/features/notifications/notification_screen.dart';
import 'package:farmer_mobile_app/features/profile/profile_screen.dart';
import 'package:farmer_mobile_app/features/profile/settings_screen.dart';
import 'package:farmer_mobile_app/features/splash/onboarding_screen.dart';
import 'package:farmer_mobile_app/features/tips/tips_screen.dart';
import 'package:farmer_mobile_app/features/weather/weather_screen.dart';
import 'package:farmer_mobile_app/shared/models/disease_model.dart';
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

      // ✅ FIXED: Combined duplicate routes and added safe type checking
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final extra = state.extra;

          // Case A: plain File
          if (extra is File) {
            return ResultScreen(
              image: extra,
              data: const {
                "disease_am": "በሂደት ላይ...",
                "disease_en": "Loading...",
                "confidence": 0.0,
              },
            );
          }

          // Case B: Map with data
          if (extra is Map) {
            final params = Map<String, dynamic>.from(extra);

            File? image;
            final rawImage = params['image'];
            if (rawImage is File && rawImage.path.isNotEmpty) {
              image = rawImage;
            }

            Map<String, dynamic> data = {};
            final rawData = params['data'];
            if (rawData is Map<String, dynamic>) {
              data = rawData;
            } else if (rawData is Map) {
              data = Map<String, dynamic>.from(rawData);
            } else if (params['result'] is Map) {
              data = Map<String, dynamic>.from(params['result'] as Map);
            }

            return ResultScreen(image: image, data: data);
          }

          // Fallback
          return const Scaffold(
            body: Center(child: Text("Error: Invalid navigation data")),
          );
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
      GoRoute(
        path: '/market',
        name: 'market',
        builder: (BuildContext context, GoRouterState state) {
          return const MarketScreen();
        },
      ),
      GoRoute(
        path: '/expert',
        name: 'expert',
        builder: (BuildContext context, GoRouterState state) {
          return const ExpertScreen();
        },
      ),
      GoRoute(
        path: '/community',
        name: 'community',
        builder: (BuildContext context, GoRouterState state) {
          return const CommunityScreen();
        },
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
