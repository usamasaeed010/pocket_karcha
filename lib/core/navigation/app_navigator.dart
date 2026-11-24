import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/navigation/app_routes.dart';

abstract final class AppNavigator {
  static void toOnboarding(BuildContext context) {
    Navigator.of(context, rootNavigator: true)
        .pushReplacementNamed(AppRoutes.onboarding);
  }

  static void toAuth(BuildContext context) {
    Navigator.of(context, rootNavigator: true)
        .pushReplacementNamed(AppRoutes.auth);
  }

  static void toCompleteProfile(BuildContext context) {
    Navigator.of(context, rootNavigator: true)
        .pushReplacementNamed(AppRoutes.completeProfile);
  }

  /// New owner (or signed in without a store yet) → create the store.
  static void toStoreSetup(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRoutes.storeSetup,
      (_) => false,
    );
  }

  static void toHome(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (_) => false,
    );
  }

  /// Old khata screens call this after logout; the start screen is now
  /// onboarding (create store / sign in).
  static void resetToAuth(BuildContext context) => resetToOnboarding(context);

  /// After logout / account deletion.
  static void resetToOnboarding(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRoutes.onboarding,
      (_) => false,
    );
  }
}
