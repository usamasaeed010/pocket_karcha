import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/category_icons.dart';
import 'package:pocket_karcha/data/models/category_model.dart';
import 'package:pocket_karcha/services/preferences_service.dart';

class CategoriesRepository {
  CategoriesRepository(this._prefs);

  final PreferencesService _prefs;

  static final List<CategoryModel> defaultGave = [
    CategoryModel(
      id: 'food',
      labelEn: 'Food',
      labelUr: 'کھانا',
      iconCodePoint: Icons.restaurant_rounded.codePoint,
      colorValue: 0xFFF97316,
      scope: CategoryScope.gave,
    ),
    CategoryModel(
      id: 'groceries',
      labelEn: 'Groceries',
      labelUr: 'گروسری',
      iconCodePoint: Icons.shopping_basket_rounded.codePoint,
      colorValue: 0xFF84CC16,
      scope: CategoryScope.gave,
    ),
    CategoryModel(
      id: 'transport',
      labelEn: 'Transport',
      labelUr: 'سفر',
      iconCodePoint: Icons.directions_car_rounded.codePoint,
      colorValue: 0xFF3B82F6,
      scope: CategoryScope.gave,
    ),
    CategoryModel(
      id: 'utilities',
      labelEn: 'Bills',
      labelUr: 'بل',
      iconCodePoint: Icons.receipt_long_rounded.codePoint,
      colorValue: 0xFF8B5CF6,
      scope: CategoryScope.gave,
    ),
    CategoryModel(
      id: 'health',
      labelEn: 'Health',
      labelUr: 'صحت',
      iconCodePoint: Icons.local_hospital_rounded.codePoint,
      colorValue: 0xFFEC4899,
      scope: CategoryScope.gave,
    ),
    CategoryModel(
      id: 'other_gave',
      labelEn: 'Other',
      labelUr: 'دیگر',
      iconCodePoint: Icons.more_horiz_rounded.codePoint,
      colorValue: 0xFF64748B,
      scope: CategoryScope.gave,
    ),
  ];

  static final List<CategoryModel> defaultGot = [
    CategoryModel(
      id: 'salary',
      labelEn: 'Salary',
      labelUr: 'تنخواہ',
      iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
      colorValue: 0xFF1B4332,
      scope: CategoryScope.got,
    ),
    CategoryModel(
      id: 'business',
      labelEn: 'Business',
      labelUr: 'کاروبار',
      iconCodePoint: Icons.business_center_rounded.codePoint,
      colorValue: 0xFFF97316,
      scope: CategoryScope.got,
    ),
    CategoryModel(
      id: 'gift_income',
      labelEn: 'Gift',
      labelUr: 'تحفہ',
      iconCodePoint: Icons.card_giftcard_rounded.codePoint,
      colorValue: 0xFF2E7D32,
      scope: CategoryScope.got,
    ),
    CategoryModel(
      id: 'other_got',
      labelEn: 'Other',
      labelUr: 'دیگر',
      iconCodePoint: Icons.more_horiz_rounded.codePoint,
      colorValue: 0xFF64748B,
      scope: CategoryScope.got,
    ),
  ];

  List<CategoryModel> _defaultsFor(CategoryScope scope) =>
      scope == CategoryScope.gave ? defaultGave : defaultGot;

  List<CategoryModel> loadAll() {
    return [
      ...forScope(CategoryScope.gave),
      ...forScope(CategoryScope.got),
    ];
  }

  List<CategoryModel> forScope(CategoryScope scope) {
    final defaults = _defaultsFor(scope);
    final custom = _loadCustom().where((c) => c.scope == scope).toList();
    final merged = defaults.map((d) => _override(d, custom)).toList();
    final extra = custom
        .where((c) => !defaults.any((d) => d.id == c.id))
        .toList();
    return [...merged, ...extra];
  }

  String? firstIdForScope(CategoryScope scope) {
    final list = forScope(scope);
    return list.isEmpty ? null : list.first.id;
  }

  CategoryModel byId(String id) {
    return loadAll().firstWhere(
      (c) => c.id == id,
      orElse: () {
        final gave = forScope(CategoryScope.gave);
        if (gave.isNotEmpty) return gave.first;
        final got = forScope(CategoryScope.got);
        return got.isNotEmpty ? got.first : defaultGave.first;
      },
    );
  }

  CategoryModel _override(CategoryModel base, List<CategoryModel> custom) {
    for (final c in custom) {
      if (c.id == base.id) return c;
    }
    return base;
  }

  List<CategoryModel> _loadCustom() {
    final raw = _prefs.customCategoriesJson;
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(CategoryModel category) async {
    final custom = _loadCustom();
    final idx = custom.indexWhere((c) => c.id == category.id);
    final saved = category.copyWith(isCustom: true);
    if (idx >= 0) {
      custom[idx] = saved;
    } else {
      custom.add(saved);
    }
    await _saveCustom(custom);
  }

  Future<CategoryModel> create({
    required String labelEn,
    required String labelUr,
    required CategoryScope scope,
    required int iconCodePoint,
    int? colorValue,
  }) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final category = CategoryModel(
      id: id,
      labelEn: labelEn,
      labelUr: labelUr,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue ?? CategoryIcons.colorForIcon(iconCodePoint),
      scope: scope,
      isCustom: true,
    );
    await save(category);
    return category;
  }

  Future<void> _saveCustom(List<CategoryModel> custom) async {
    final json = jsonEncode(custom.map((c) => c.toJson()).toList());
    await _prefs.setCustomCategoriesJson(json);
  }
}
