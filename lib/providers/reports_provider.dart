import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/data/models/category_model.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';

/// First day of the month shown on the Reports tab.
final reportMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

bool _inMonth(DateTime date, DateTime month) =>
    date.year == month.year && date.month == month.month;

class MonthSummary {
  const MonthSummary({
    required this.month,
    required this.sales,
    required this.purchases,
    required this.expenses,
    required this.count,
    required this.days,
  });

  factory MonthSummary.from(DateTime month, Iterable<ExpenseModel> items) {
    var sales = 0.0;
    var purchases = 0.0;
    var expenses = 0.0;
    var count = 0;
    for (final e in items) {
      count++;
      switch (e.type) {
        case ExpenseRecordType.income:
          sales += e.amount;
        case ExpenseRecordType.purchase:
          purchases += e.amount;
        case ExpenseRecordType.expense:
          expenses += e.amount;
      }
    }
    final now = DateTime.now();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final days = _inMonth(now, month) ? now.day : daysInMonth;
    return MonthSummary(
      month: month,
      sales: sales,
      purchases: purchases,
      expenses: expenses,
      count: count,
      days: days,
    );
  }

  final DateTime month;
  final double sales;
  final double purchases;
  final double expenses;
  final int count;

  /// Days counted for averages (days so far for the current month).
  final int days;

  double get spending => purchases + expenses;
  double get profit => sales - spending;
  bool get isLoss => profit < 0;
  bool get isEmpty => count == 0;

  /// Profit as % of sales, or null when there were no sales.
  double? get marginPercent => sales > 0 ? profit / sales * 100 : null;
  double get avgDailySales => days > 0 ? sales / days : 0;
}

final reportTransactionsProvider = Provider<List<ExpenseModel>>((ref) {
  final all = ref.watch(expensesStreamProvider).valueOrNull ?? const [];
  final month = ref.watch(reportMonthProvider);
  return all.where((e) => _inMonth(e.date, month)).toList();
});

final reportSummaryProvider = Provider<MonthSummary>((ref) {
  return MonthSummary.from(
    ref.watch(reportMonthProvider),
    ref.watch(reportTransactionsProvider),
  );
});

/// Six months ending with the selected month (oldest first).
final reportTrendProvider = Provider<List<MonthSummary>>((ref) {
  final all = ref.watch(expensesStreamProvider).valueOrNull ?? const [];
  final selected = ref.watch(reportMonthProvider);
  return [
    for (var i = 5; i >= 0; i--)
      () {
        final month = DateTime(selected.year, selected.month - i);
        return MonthSummary.from(
          month,
          all.where((e) => _inMonth(e.date, month)),
        );
      }(),
  ];
});

class CategoryShare {
  const CategoryShare({
    required this.category,
    required this.amount,
    required this.count,
    required this.fraction,
  });

  final CategoryModel category;
  final double amount;
  final int count;

  /// Share of the total for this entry kind (0–1).
  final double fraction;
}

/// Category totals for one entry kind in the selected month, largest first.
final reportCategoryBreakdownProvider =
    Provider.family<List<CategoryShare>, ExpenseRecordType>((ref, type) {
  final items = ref
      .watch(reportTransactionsProvider)
      .where((e) => e.type == type)
      .toList();
  if (items.isEmpty) return const [];

  final totals = <String, double>{};
  final counts = <String, int>{};
  var grand = 0.0;
  for (final e in items) {
    totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amount;
    counts[e.categoryId] = (counts[e.categoryId] ?? 0) + 1;
    grand += e.amount;
  }

  final shares = totals.entries
      .map(
        (entry) => CategoryShare(
          category: ref.watch(categoryByIdProvider(entry.key)),
          amount: entry.value,
          count: counts[entry.key] ?? 0,
          fraction: grand > 0 ? entry.value / grand : 0,
        ),
      )
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return shares;
});

class ItemStat {
  const ItemStat({
    required this.name,
    required this.unit,
    required this.quantity,
    required this.amount,
    required this.count,
  });

  final String name;
  final String? unit;
  final double quantity;
  final double amount;
  final int count;

  double? get avgRate => quantity > 0 ? amount / quantity : null;
}

/// Items bought (or sold) most in the selected month, by amount.
final reportTopItemsProvider =
    Provider.family<List<ItemStat>, ExpenseRecordType>((ref, type) {
  final items = ref
      .watch(reportTransactionsProvider)
      .where((e) => e.type == type && e.hasItemName);

  final names = <String, String>{};
  final units = <String, String?>{};
  final qty = <String, double>{};
  final amounts = <String, double>{};
  final counts = <String, int>{};

  for (final e in items) {
    final name = e.itemName!.trim();
    final key = '${name.toLowerCase()}|${e.unit ?? ''}';
    names.putIfAbsent(key, () => name);
    units.putIfAbsent(key, () => e.unit);
    qty[key] = (qty[key] ?? 0) + (e.hasQuantity ? e.quantity! : 0);
    amounts[key] = (amounts[key] ?? 0) + e.amount;
    counts[key] = (counts[key] ?? 0) + 1;
  }

  final stats = amounts.keys
      .map(
        (key) => ItemStat(
          name: names[key]!,
          unit: units[key],
          quantity: qty[key] ?? 0,
          amount: amounts[key] ?? 0,
          count: counts[key] ?? 0,
        ),
      )
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return stats.take(10).toList();
});
