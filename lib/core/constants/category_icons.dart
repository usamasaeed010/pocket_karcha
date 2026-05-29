import 'package:flutter/material.dart';

/// Curated Material icons for category picker.
abstract final class CategoryIcons {
  static const List<Color> colors = [
    Color(0xFFF97316),
    Color(0xFF84CC16),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF0D9488),
    Color(0xFF6366F1),
    Color(0xFFE53935),
    Color(0xFF2E7D32),
    Color(0xFF64748B),
  ];

  static const List<IconData> pickable = [
    Icons.restaurant_rounded,
    Icons.fastfood_rounded,
    Icons.local_cafe_rounded,
    Icons.shopping_basket_rounded,
    Icons.shopping_cart_rounded,
    Icons.storefront_rounded,
    Icons.directions_car_rounded,
    Icons.local_gas_station_rounded,
    Icons.flight_rounded,
    Icons.directions_bus_rounded,
    Icons.home_rounded,
    Icons.lightbulb_outline_rounded,
    Icons.receipt_long_rounded,
    Icons.phone_android_rounded,
    Icons.wifi_rounded,
    Icons.local_hospital_rounded,
    Icons.fitness_center_rounded,
    Icons.school_rounded,
    Icons.menu_book_rounded,
    Icons.child_care_rounded,
    Icons.pets_rounded,
    Icons.checkroom_rounded,
    Icons.spa_rounded,
    Icons.movie_rounded,
    Icons.sports_esports_rounded,
    Icons.card_giftcard_rounded,
    Icons.celebration_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.business_center_rounded,
    Icons.payments_rounded,
    Icons.savings_rounded,
    Icons.trending_up_rounded,
    Icons.work_rounded,
    Icons.build_rounded,
    Icons.handyman_rounded,
    Icons.more_horiz_rounded,
    Icons.category_rounded,
    Icons.label_outline_rounded,
    Icons.favorite_rounded,
    Icons.volunteer_activism_rounded,
  ];

  static int colorForIndex(int index) =>
      colors[index % colors.length].value;

  static int colorForIcon(int iconCodePoint) {
    final i = pickable.indexWhere((ic) => ic.codePoint == iconCodePoint);
    return colorForIndex(i >= 0 ? i : 0);
  }
}
