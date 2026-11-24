import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/category_icons.dart';
import 'package:pocket_karcha/data/models/category_model.dart';
import 'package:pocket_karcha/services/preferences_service.dart';

class CategoriesRepository {
  CategoriesRepository(this._prefs);

  final PreferencesService _prefs;

  /// Purchase (stock / raw material) categories.
  static final List<CategoryModel> defaultStock = [
    CategoryModel(
      id: 'stock_fruits',
      labelEn: 'Fruits',
      labelUr: 'پھل',
      iconCodePoint: Icons.eco_rounded.codePoint,
      colorValue: 0xFF16A34A,
      scope: CategoryScope.stock,
    ),
    CategoryModel(
      id: 'stock_vegetables',
      labelEn: 'Vegetables',
      labelUr: 'سبزیاں',
      iconCodePoint: Icons.grass_rounded.codePoint,
      colorValue: 0xFF65A30D,
      scope: CategoryScope.stock,
    ),
    CategoryModel(
      id: 'stock_meat',
      labelEn: 'Meat & Chicken',
      labelUr: 'گوشت و مرغی',
      iconCodePoint: Icons.set_meal_rounded.codePoint,
      colorValue: 0xFFDC2626,
      scope: CategoryScope.stock,
    ),
    CategoryModel(
      id: 'stock_dairy',
      labelEn: 'Milk, Eggs & Dairy',
      labelUr: 'دودھ، انڈے و ڈیری',
      iconCodePoint: Icons.egg_rounded.codePoint,
      colorValue: 0xFF0EA5E9,
      scope: CategoryScope.stock,
    ),
    CategoryModel(
      id: 'stock_bakery',
      labelEn: 'Bread & Buns',
      labelUr: 'بیکری، بن و ڈبل روٹی',
      iconCodePoint: Icons.bakery_dining_rounded.codePoint,
      colorValue: 0xFFD97706,
      scope: CategoryScope.stock,
    ),
    CategoryModel(
      id: 'stock_grocery',
      labelEn: 'Grocery & Spices',
      labelUr: 'کریانہ و مصالحہ',
      iconCodePoint: Icons.local_grocery_store_rounded.codePoint,
      colorValue: 0xFF7C3AED,
      scope: CategoryScope.stock,
    ),
    CategoryModel(
      id: 'stock_drinks',
      labelEn: 'Drinks & Ice',
      labelUr: 'مشروبات و برف',
      iconCodePoint: Icons.local_drink_rounded.codePoint,
      colorValue: 0xFF0891B2,
      scope: CategoryScope.stock,
    ),
    CategoryModel(
      id: 'stock_packaging',
      labelEn: 'Packing & Disposables',
      labelUr: 'پیکنگ و ڈسپوزیبل',
      iconCodePoint: Icons.takeout_dining_rounded.codePoint,
      colorValue: 0xFFDB2777,
      scope: CategoryScope.stock,
    ),
    CategoryModel(
      id: 'stock_other',
      labelEn: 'Other Stock',
      labelUr: 'دیگر سامان',
      iconCodePoint: Icons.inventory_2_rounded.codePoint,
      colorValue: 0xFF475569,
      scope: CategoryScope.stock,
    ),
  ];

  /// Shop running-expense categories.
  static final List<CategoryModel> defaultGave = [
    CategoryModel(
      id: 'exp_rent',
      labelEn: 'Shop Rent',
      labelUr: 'دکان کا کرایہ',
      iconCodePoint: Icons.store_rounded.codePoint,
      colorValue: 0xFF7C3AED,
      scope: CategoryScope.gave,
    ),
    CategoryModel(
      id: 'utilities',
      labelEn: 'Bills (Electricity, Water)',
      labelUr: 'بل (بجلی، پانی)',
      iconCodePoint: Icons.lightbulb_outline_rounded.codePoint,
      colorValue: 0xFFF59E0B,
      scope: CategoryScope.gave,
    ),
    CategoryModel(
      id: 'exp_salary',
      labelEn: 'Staff Salary',
      labelUr: 'عملے کی تنخواہ',
      iconCodePoint: Icons.people_alt_rounded.codePoint,
      colorValue: 0xFF2563EB,
      scope: CategoryScope.gave,
    ),
    CategoryModel(
      id: 'exp_gas',
      labelEn: 'Gas Cylinder & Fuel',
      labelUr: 'گیس سلنڈر و ایندھن',
      iconCodePoint: Icons.propane_tank_rounded.codePoint,
      colorValue: 0xFFEA580C,
      scope: CategoryScope.gave,
    ),
    CategoryModel(
      id: 'transport',
      labelEn: 'Transport & Delivery',
      labelUr: 'ٹرانسپورٹ و ڈلیوری',
      iconCodePoint: Icons.local_shipping_rounded.codePoint,
      colorValue: 0xFF0891B2,
      scope: CategoryScope.gave,
    ),
    CategoryModel(
      id: 'exp_maintenance',
      labelEn: 'Repairs & Maintenance',
      labelUr: 'مرمت و دیکھ بھال',
      iconCodePoint: Icons.build_rounded.codePoint,
      colorValue: 0xFF64748B,
      scope: CategoryScope.gave,
    ),
    CategoryModel(
      id: 'exp_fees',
      labelEn: 'Taxes & Fees',
      labelUr: 'ٹیکس و فیس',
      iconCodePoint: Icons.request_quote_rounded.codePoint,
      colorValue: 0xFF0D9488,
      scope: CategoryScope.gave,
    ),
    CategoryModel(
      id: 'other_gave',
      labelEn: 'Other Expense',
      labelUr: 'دیگر خرچہ',
      iconCodePoint: Icons.more_horiz_rounded.codePoint,
      colorValue: 0xFF64748B,
      scope: CategoryScope.gave,
    ),
  ];

  /// Sale / money-in categories.
  static final List<CategoryModel> defaultGot = [
    CategoryModel(
      id: 'sale_daily',
      labelEn: 'Daily Sales',
      labelUr: 'روزانہ فروخت',
      iconCodePoint: Icons.point_of_sale_rounded.codePoint,
      colorValue: 0xFF059669,
      scope: CategoryScope.got,
    ),
    CategoryModel(
      id: 'sale_online',
      labelEn: 'Online & Delivery Orders',
      labelUr: 'آن لائن و ڈلیوری آرڈر',
      iconCodePoint: Icons.delivery_dining_rounded.codePoint,
      colorValue: 0xFF2563EB,
      scope: CategoryScope.got,
    ),
    CategoryModel(
      id: 'sale_bulk',
      labelEn: 'Catering & Bulk Orders',
      labelUr: 'کیٹرنگ و بڑے آرڈر',
      iconCodePoint: Icons.room_service_rounded.codePoint,
      colorValue: 0xFF7C3AED,
      scope: CategoryScope.got,
    ),
    CategoryModel(
      id: 'other_got',
      labelEn: 'Other Income',
      labelUr: 'دیگر آمدنی',
      iconCodePoint: Icons.more_horiz_rounded.codePoint,
      colorValue: 0xFF64748B,
      scope: CategoryScope.got,
    ),
  ];

  /// Categories from the old personal-expense version. Hidden from pickers but
  /// still resolvable so older entries keep their label and icon.
  static final List<CategoryModel> _legacy = [
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
      id: 'health',
      labelEn: 'Health',
      labelUr: 'صحت',
      iconCodePoint: Icons.local_hospital_rounded.codePoint,
      colorValue: 0xFFEC4899,
      scope: CategoryScope.gave,
    ),
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
  ];

  List<CategoryModel> _defaultsFor(CategoryScope scope) => switch (scope) {
        CategoryScope.gave => defaultGave,
        CategoryScope.got => defaultGot,
        CategoryScope.stock => defaultStock,
      };

  List<CategoryModel> loadAll() {
    return [
      for (final scope in CategoryScope.values) ...forScope(scope),
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
    for (final c in loadAll()) {
      if (c.id == id) return c;
    }
    for (final c in _legacy) {
      if (c.id == id) return c;
    }
    return defaultGave.last;
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
