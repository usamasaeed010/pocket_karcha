import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';

class TransactionTypeLook {
  const TransactionTypeLook({
    required this.type,
    required this.color,
    required this.colorLight,
    required this.onColor,
    required this.surface,
    required this.border,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final TransactionType type;
  final Color color;
  final Color colorLight;
  final Color onColor;
  final Color surface;
  final Color border;
  final IconData icon;
  final String title;
  final String subtitle;

  /// "+" for money in, "−" for money out.
  String get sign => type.isIncome ? '+' : '-';

  List<Color> get gradient => [color, colorLight];
}

TransactionTypeLook lookFor(TransactionType type, AppStrings strings) {
  switch (type) {
    case TransactionType.got:
      return TransactionTypeLook(
        type: type,
        color: AppColors.sale,
        colorLight: AppColors.saleLight,
        onColor: Colors.white,
        surface: const Color(0xFFECFDF5),
        border: const Color(0xFFA7F3D0),
        icon: Icons.point_of_sale_rounded,
        title: strings.youGot,
        subtitle: strings.youGotHint,
      );
    case TransactionType.purchase:
      return TransactionTypeLook(
        type: type,
        color: AppColors.purchase,
        colorLight: AppColors.purchaseLight,
        onColor: Colors.white,
        surface: const Color(0xFFFFFBEB),
        border: const Color(0xFFFDE68A),
        icon: Icons.shopping_cart_rounded,
        title: strings.purchase,
        subtitle: strings.purchaseHint,
      );
    case TransactionType.gave:
      return TransactionTypeLook(
        type: type,
        color: AppColors.expense,
        colorLight: AppColors.expenseLight,
        onColor: Colors.white,
        surface: const Color(0xFFFFF1F2),
        border: const Color(0xFFFECDD3),
        icon: Icons.payments_rounded,
        title: strings.youGave,
        subtitle: strings.youGaveHint,
      );
  }
}
