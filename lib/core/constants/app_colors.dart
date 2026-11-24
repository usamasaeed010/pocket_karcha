import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Order-app palette (cream page, deep green brand) ──────────────────
  /// Warm cream page background.
  static const Color cream = Color(0xFFFAF6EE);

  /// Card surface on the cream page.
  static const Color creamCard = Color(0xFFFFFDF9);

  /// Hairline border for cards, inputs and chips.
  static const Color creamBorder = Color(0xFFEDE6D8);

  /// Slightly darker cream used for pressed / muted fills.
  static const Color creamDeep = Color(0xFFF3EDE1);

  static const Color ink = Color(0xFF1F1D1A);
  static const Color inkSoft = Color(0xFF7B7468);
  static const Color inkFaint = Color(0xFFA9A194);

  static const Color brand = Color(0xFF13784B);
  static const Color brandDark = Color(0xFF0D5E3A);
  static const Color brandSoft = Color(0xFFE3F1E7);
  static const Color brandSoftBorder = Color(0xFFCBE5D3);

  /// WhatsApp-style bright green for share buttons.
  static const Color whatsapp = Color(0xFF1FBF5F);

  static const Color peach = Color(0xFFFCE9DA);
  static const Color pending = Color(0xFFDD7F1F);
  static const Color pendingSoft = Color(0xFFFCEBD5);
  static const Color dispatched = Color(0xFF2F6FDB);
  static const Color dispatchedSoft = Color(0xFFE5EDFB);
  static const Color danger = Color(0xFFD14343);
  static const Color dangerSoft = Color(0xFFFBE7E7);
  static const Color backupBlue = Color(0xFFE9F1FC);
  static const Color backupBlueBorder = Color(0xFFCFE0F7);

  // ── Brand (kept names — used across older screens too) ────────────────
  static const Color primary = brand;
  static const Color primaryDark = brandDark;
  static const Color primaryLight = Color(0xFF2E9E69);

  // Dashboard
  static const Color dashboardGreen = Color(0xFF0D5E3A);
  static const Color dashboardGreenLight = Color(0xFF13784B);
  static const Color dashboardSurface = cream;
  static const Color upgradeBronze = Color(0xFF8B6914);
  static const Color upgradeBronzeLight = Color(0xFFB8860B);

  /// Profit hero card.
  static const List<Color> heroGradient = [
    Color(0xFF0B4A2E),
    Color(0xFF0D5E3A),
    Color(0xFF13784B),
  ];

  /// Hero card when the period is running at a loss.
  static const List<Color> lossGradient = [
    Color(0xFF881337),
    Color(0xFFBE123C),
    Color(0xFFE11D48),
  ];

  static const Color surface = cream;
  static const Color card = creamCard;
  static const Color border = creamBorder;
  static const Color divider = Color(0xFFF1ECE2);
  static const Color textPrimary = ink;
  static const Color textSecondary = inkSoft;

  // Entry kinds
  static const Color sale = Color(0xFF059669);
  static const Color saleLight = Color(0xFF10B981);
  static const Color purchase = Color(0xFFD97706);
  static const Color purchaseLight = Color(0xFFF59E0B);
  static const Color expense = Color(0xFFE11D48);
  static const Color expenseLight = Color(0xFFFB7185);
  static const Color expenseDark = Color(0xFFBE123C);

  static const Color success = brand;
  static const Color successLight = Color(0xFF2E9E69);
  static const Color warning = Color(0xFFF59E0B);
  static const Color spentBar = Color(0xFFF97316);
  static const Color availableBar = Color(0xFFE2E8F0);

  static const Color splashBackground = Color(0xFF0D5E3A);
  static const Color navActive = brand;
  static const Color navInactive = Color(0xFF8F887B);

  /// Soft card shadow used across the app.
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF3B2F1A).withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ];
}
