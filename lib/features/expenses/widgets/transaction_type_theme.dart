import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';

class TransactionTypeLook {
  const TransactionTypeLook({
    required this.color,
    required this.onColor,
    required this.surface,
    required this.border,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final Color onColor;
  final Color surface;
  final Color border;
  final IconData icon;
  final String title;
  final String subtitle;
}

TransactionTypeLook lookFor(TransactionType type, AppStrings strings) {
  switch (type) {
    case TransactionType.gave:
      return TransactionTypeLook(
        color: AppColors.expense,
        onColor: Colors.white,
        surface: const Color(0xFFFFF5F5),
        border: const Color(0xFFFECACA),
        icon: Icons.arrow_upward_rounded,
        title: strings.youGave,
        subtitle: strings.youGaveHint,
      );
    case TransactionType.got:
      return TransactionTypeLook(
        color: AppColors.navActive,
        onColor: Colors.white,
        surface: const Color(0xFFF0FDF4),
        border: const Color(0xFFBBF7D0),
        icon: Icons.arrow_downward_rounded,
        title: strings.youGot,
        subtitle: strings.youGotHint,
      );
  }
}
