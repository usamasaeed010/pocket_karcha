import 'package:flutter/material.dart';

/// A built-in category for personal (home) spending. Saved as the entry's
/// `categoryId` on entries with `book: personal`.
class PersonalCategory {
  const PersonalCategory(this.id, this.en, this.ur, this.icon, this.color);

  final String id;
  final String en;
  final String ur;
  final IconData icon;
  final Color color;

  String label(bool urdu) => urdu ? ur : en;
}

abstract final class PersonalCategories {
  static const other = PersonalCategory(
    'p_other',
    'Other',
    'دیگر',
    Icons.more_horiz_rounded,
    Color(0xFF7B7468),
  );

  static const all = <PersonalCategory>[
    PersonalCategory(
      'p_food',
      'Food & grocery',
      'کھانا اور راشن',
      Icons.shopping_basket_rounded,
      Color(0xFF13784B),
    ),
    PersonalCategory(
      'p_transport',
      'Petrol & travel',
      'پیٹرول اور سفر',
      Icons.two_wheeler_rounded,
      Color(0xFF2F6FDB),
    ),
    PersonalCategory(
      'p_bills',
      'Bills',
      'بل',
      Icons.bolt_rounded,
      Color(0xFFDD7F1F),
    ),
    PersonalCategory(
      'p_rent',
      'House rent',
      'گھر کا کرایہ',
      Icons.home_rounded,
      Color(0xFF7C3AED),
    ),
    PersonalCategory(
      'p_mobile',
      'Mobile & internet',
      'موبائل اور انٹرنیٹ',
      Icons.wifi_rounded,
      Color(0xFF0284C7),
    ),
    PersonalCategory(
      'p_health',
      'Health',
      'صحت اور دوائی',
      Icons.medical_services_rounded,
      Color(0xFFD14343),
    ),
    PersonalCategory(
      'p_education',
      'Education',
      'تعلیم',
      Icons.school_rounded,
      Color(0xFF4F46E5),
    ),
    PersonalCategory(
      'p_clothes',
      'Clothes & shopping',
      'کپڑے اور شاپنگ',
      Icons.checkroom_rounded,
      Color(0xFFDB2777),
    ),
    PersonalCategory(
      'p_family',
      'Family & gifts',
      'خاندان اور تحفے',
      Icons.card_giftcard_rounded,
      Color(0xFFB45309),
    ),
    PersonalCategory(
      'p_charity',
      'Charity',
      'صدقہ و خیرات',
      Icons.volunteer_activism_rounded,
      Color(0xFF059669),
    ),
    other,
  ];

  static PersonalCategory byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => other);
}
