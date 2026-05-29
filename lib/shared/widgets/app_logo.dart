import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';

/// App launcher logo — same asset as app icon.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 96,
    this.borderRadius = 24,
    this.showShadow = true,
  });

  final double size;
  final double borderRadius;
  final bool showShadow;

  static const assetPath = 'assets/images/app_icon.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: AppColors.dashboardGreenLight.withValues(alpha: 0.35),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.dashboardGreenLight,
            alignment: Alignment.center,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: size * 0.52,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
