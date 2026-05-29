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

  static void toHome(BuildContext context) {
    Navigator.of(context, rootNavigator: true)
        .pushReplacementNamed(AppRoutes.home);
  }

  static void resetToAuth(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRoutes.auth,
      (_) => false,
    );
  }
}
