import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/core/utils/date_utils.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';

class CategorySlice {
  const CategorySlice({
    required this.categoryId,
    required this.total,
    required this.color,
    required this.label,
  });

  final String categoryId;
  final double total;
  final Color color;
  final String label;
}

final categoryChartProvider = Provider<List<CategorySlice>>((ref) {
  final urdu = ref.watch(localeUrduProvider);
  final expenses = ref.watch(expensesStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final thisMonth =
      expenses.where((e) => AppDateUtils.isSameMonth(e.date, now));

  final totals = <String, double>{};
  for (final e in thisMonth) {
    totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amount;
  }

  return totals.entries
      .map((e) {
        final cat = ref.watch(categoryByIdProvider(e.key));
        return CategorySlice(
          categoryId: e.key,
          total: e.value,
          color: cat.color,
          label: urdu ? cat.labelUr : cat.labelEn,
        );
      })
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));
});
