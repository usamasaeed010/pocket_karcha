import 'package:flutter/material.dart';

class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.labelEn,
    required this.labelUr,
    required this.icon,
    required this.color,
  });

  final String id;
  final String labelEn;
  final String labelUr;
  final IconData icon;
  final Color color;
}

abstract final class PkCategories {
  static const List<ExpenseCategory> all = [
    ExpenseCategory(
      id: 'food',
      labelEn: 'Food',
      labelUr: 'کھانا',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFF97316),
    ),
    ExpenseCategory(
      id: 'groceries',
      labelEn: 'Groceries',
      labelUr: 'گروسری',
      icon: Icons.shopping_basket_rounded,
      color: Color(0xFF84CC16),
    ),
    ExpenseCategory(
      id: 'transport',
      labelEn: 'Transport',
      labelUr: 'سفر',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF3B82F6),
    ),
    ExpenseCategory(
      id: 'utilities',
      labelEn: 'Bills',
      labelUr: 'بل',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF8B5CF6),
    ),
    ExpenseCategory(
      id: 'education',
      labelEn: 'Education',
      labelUr: 'تعلیم',
      icon: Icons.school_rounded,
      color: Color(0xFF06B6D4),
    ),
    ExpenseCategory(
      id: 'health',
      labelEn: 'Health',
      labelUr: 'صحت',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFFEC4899),
    ),
    ExpenseCategory(
      id: 'transfer',
      labelEn: 'Transfer',
      labelUr: 'ٹرانسفر',
      icon: Icons.swap_horiz_rounded,
      color: Color(0xFF6366F1),
    ),
    ExpenseCategory(
      id: 'other',
      labelEn: 'Other',
      labelUr: 'دیگر',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF64748B),
    ),
  ];

  static ExpenseCategory byId(String id) {
    return all.firstWhere(
      (c) => c.id == id,
      orElse: () => all.last,
    );
  }
}
