import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pocket_karcha/data/models/expense_suggestion.dart';

/// Pakistan-market quick-add suggestions for expenses.
abstract final class PkExpenseSuggestions {
  static List<ExpenseSuggestion>? _cache;

  static const List<ExpenseSuggestion> defaults = [
    ExpenseSuggestion(
      titleEn: 'Biryani',
      titleUr: 'بریانی',
      categoryId: 'food',
      amount: 450,
    ),
    ExpenseSuggestion(
      titleEn: 'Petrol',
      titleUr: 'پٹرول',
      categoryId: 'transport',
      amount: 2000,
    ),
    ExpenseSuggestion(
      titleEn: 'Electricity bill',
      titleUr: 'بجلی بل',
      categoryId: 'utilities',
      amount: 5500,
    ),
    ExpenseSuggestion(
      titleEn: 'EasyPaisa',
      titleUr: 'ایزی پیسہ',
      categoryId: 'transfer',
      amount: 1000,
    ),
    ExpenseSuggestion(
      titleEn: 'School fee',
      titleUr: 'سکول فیس',
      categoryId: 'education',
      amount: 8000,
    ),
    ExpenseSuggestion(
      titleEn: 'Sabzi',
      titleUr: 'سبزی',
      categoryId: 'groceries',
      amount: 800,
    ),
    ExpenseSuggestion(
      titleEn: 'Mobile recharge',
      titleUr: 'ریچارج',
      categoryId: 'utilities',
      amount: 500,
    ),
    ExpenseSuggestion(
      titleEn: 'Careem / InDrive',
      titleUr: 'سواری',
      categoryId: 'transport',
      amount: 350,
    ),
  ];

  static Future<List<ExpenseSuggestion>> load() async {
    if (_cache != null) return _cache!;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/pk_suggestions.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _cache = list
          .map(
            (e) => ExpenseSuggestion(
              titleEn: e['titleEn'] as String,
              titleUr: e['titleUr'] as String,
              categoryId: e['categoryId'] as String,
              amount: (e['amount'] as num).toDouble(),
            ),
          )
          .toList();
      return _cache!;
    } catch (_) {
      _cache = defaults;
      return defaults;
    }
  }
}
