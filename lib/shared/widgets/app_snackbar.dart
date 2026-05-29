import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';

enum AppSnackType { success, error, info, warning }

/// Shows a styled floating snackbar for success, error, info, or warning.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppSnackType type = AppSnackType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: EdgeInsets.zero,
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        content: _AppSnackContent(message: message, type: type),
      ),
    );
}

extension AppSnackContext on BuildContext {
  void showSuccessSnack(String message) =>
      showAppSnackBar(this, message: message, type: AppSnackType.success);

  void showErrorSnack(String message) =>
      showAppSnackBar(this, message: message, type: AppSnackType.error);

  void showInfoSnack(String message) =>
      showAppSnackBar(this, message: message, type: AppSnackType.info);

  void showWarningSnack(String message) =>
      showAppSnackBar(this, message: message, type: AppSnackType.warning);
}

class _AppSnackContent extends StatelessWidget {
  const _AppSnackContent({
    required this.message,
    required this.type,
  });

  final String message;
  final AppSnackType type;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(type);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: style.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: style.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: style.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: style.textColor.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _SnackStyle _styleFor(AppSnackType type) {
    switch (type) {
      case AppSnackType.success:
        return const _SnackStyle(
          background: Color(0xFFE8F5E9),
          border: Color(0xFFA5D6A7),
          iconBackground: Color(0xFFC8E6C9),
          iconColor: AppColors.success,
          textColor: Color(0xFF1B5E20),
          icon: Icons.check_circle_rounded,
        );
      case AppSnackType.error:
        return const _SnackStyle(
          background: Color(0xFFFFEBEE),
          border: Color(0xFFEF9A9A),
          iconBackground: Color(0xFFFFCDD2),
          iconColor: AppColors.expense,
          textColor: Color(0xFFB71C1C),
          icon: Icons.error_outline_rounded,
        );
      case AppSnackType.warning:
        return const _SnackStyle(
          background: Color(0xFFFFF7ED),
          border: Color(0xFFFDBA74),
          iconBackground: Color(0xFFFFEDD5),
          iconColor: Color(0xFFEA580C),
          textColor: Color(0xFF9A3412),
          icon: Icons.warning_amber_rounded,
        );
      case AppSnackType.info:
        return const _SnackStyle(
          background: Color(0xFFEFF6FF),
          border: Color(0xFF93C5FD),
          iconBackground: Color(0xFFDBEAFE),
          iconColor: Color(0xFF2563EB),
          textColor: Color(0xFF1E3A8A),
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _SnackStyle {
  const _SnackStyle({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color iconBackground;
  final Color iconColor;
  final Color textColor;
  final IconData icon;
}
