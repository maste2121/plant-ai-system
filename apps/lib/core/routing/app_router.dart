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

          // 🛡️ 1. Handle case where extra is just a File (Legacy/Simple view)
          if (extra is File) {
            return ResultDetailScreen(
              image: extra,
              resultData: const {
                "disease_am": "በሂደት ላይ...",
                "disease_en": "Loading...",
                "confidence": 0.0,
                "treatments": {},
              },
            );
          }

          // 🛡️ 2. Handle case where extra is a Map (Real Data)
          if (extra is Map) {
            // ✅ THE CRITICAL FIX: Convert generic Map to strictly typed Map<String, dynamic>
            final Map<String, dynamic> params = Map<String, dynamic>.from(
              extra,
            );

            // Case A: Mock/Previous logic using 'result' object
            if (params.containsKey('result')) {
              return ResultScreen(
                image: params['image'] as File,
                result: params['result'] as DiseaseResult,
              );
            }
            // Case B: Real AI logic using 'data' Map from Node.js
            else if (params.containsKey('data')) {
              return ResultDetailScreen(
                image: params['image'] as File,
                // ✅ FIX: Also cast the nested AI data map
                resultData: Map<String, dynamic>.from(params['data']),
              );
            }
          }

          // 3. Fallback
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
