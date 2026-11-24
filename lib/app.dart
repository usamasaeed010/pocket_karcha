import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/lifecycle/app_lifecycle.dart';
import 'package:pocket_karcha/providers/analytics_provider.dart';
import 'package:pocket_karcha/services/firebase_service.dart';
import 'package:pocket_karcha/core/navigation/app_routes.dart';
import 'package:pocket_karcha/core/theme/app_theme.dart';
import 'package:pocket_karcha/features/auth/presentation/auth_screen.dart';
import 'package:pocket_karcha/features/auth/presentation/complete_profile_screen.dart';
import 'package:pocket_karcha/features/home/presentation/home_screen.dart';
import 'package:pocket_karcha/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pocket_karcha/features/splash/presentation/splash_screen.dart';
import 'package:pocket_karcha/features/store_setup/presentation/store_setup_screen.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';

class PocketKarchaApp extends ConsumerWidget {
  const PocketKarchaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urdu = ref.watch(localeUrduProvider);
    ref.watch(analyticsUserSyncProvider);
    final analytics = FirebaseService.analytics;
    return AppLifecycleWrapper(
      child: MaterialApp(
        title: 'Pocket Karcha',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(urdu: urdu),
        navigatorObservers: [
          if (analytics != null)
            FirebaseAnalyticsObserver(analytics: analytics),
        ],
        scaffoldMessengerKey: rootMessengerKey,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.auth: (_) => const AuthScreen(),
          AppRoutes.completeProfile: (_) => const CompleteProfileScreen(),
          AppRoutes.storeSetup: (_) => const StoreSetupScreen(),
          AppRoutes.home: (_) => const HomeScreen(),
        },
      ),
    );
  }
}
