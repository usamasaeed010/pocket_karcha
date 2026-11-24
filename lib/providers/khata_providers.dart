import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';

// ── Khata tab ──────────────────────────────────────────────────────────────

abstract final class KhataSegments {
  static const shop = 0;
  static const personal = 1;
  static const people = 2;
}

final khataSegmentProvider = StateProvider<int>((ref) => KhataSegments.shop);

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

// ── Shop: this month ───────────────────────────────────────────────────────

class ShopMonthSummary {
  const ShopMonthSummary({
    this.sales = 0,
    this.purchases = 0,
    this.expenses = 0,
  });

  final double sales;
  final double purchases;
  final double expenses;

  double get profit => sales - purchases - expenses;
}

final shopMonthSummaryProvider = Provider<ShopMonthSummary>((ref) {
  final shop = ref.watch(expensesStreamProvider).valueOrNull ?? const [];
  final now = DateTime.now();
  var sales = 0.0;
  var purchases = 0.0;
  var expenses = 0.0;
  for (final e in shop) {
    if (!_sameMonth(e.date, now)) continue;
    switch (e.type) {
      case ExpenseRecordType.income:
        sales += e.amount;
      case ExpenseRecordType.purchase:
        purchases += e.amount;
      case ExpenseRecordType.expense:
        expenses += e.amount;
    }
  }
  return ShopMonthSummary(
    sales: sales,
    purchases: purchases,
    expenses: expenses,
  );
});

/// Latest shop entries (the stream is newest first).
final recentShopEntriesProvider = Provider<List<ExpenseModel>>((ref) {
  final shop = ref.watch(expensesStreamProvider).valueOrNull ?? const [];
  return shop.take(6).toList();
});

/// Shop udhaar: pending sales to collect and purchases / expenses to pay.
class PendingSummary {
  const PendingSummary({
    this.toCollect = 0,
    this.toPay = 0,
    this.entries = const [],
  });

  final double toCollect;
  final double toPay;

  /// Newest first.
  final List<ExpenseModel> entries;

  bool get isEmpty => entries.isEmpty;
}

final shopPendingProvider = Provider<PendingSummary>((ref) {
  final shop = ref.watch(expensesStreamProvider).valueOrNull ?? const [];
  var collect = 0.0;
  var pay = 0.0;
  final pending = <ExpenseModel>[];
  for (final e in shop) {
    if (!e.isPending) continue;
    pending.add(e);
    if (e.isIncome) {
      collect += e.amount;
    } else {
      pay += e.amount;
    }
  }
  return PendingSummary(toCollect: collect, toPay: pay, entries: pending);
});

// ── Personal ───────────────────────────────────────────────────────────────

/// First day of the month shown in the Personal view.
final personalMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final personalEntriesProvider = Provider<List<ExpenseModel>>((ref) {
  final all = ref.watch(allEntriesStreamProvider).valueOrNull ?? const [];
  return all.where((e) => e.book == EntryBook.personal).toList();
});

final personalMonthEntriesProvider = Provider<List<ExpenseModel>>((ref) {
  final month = ref.watch(personalMonthProvider);
  return ref
      .watch(personalEntriesProvider)
      .where((e) => _sameMonth(e.date, month))
      .toList();
});

final personalMonthTotalProvider = Provider<double>((ref) {
  return ref
      .watch(personalMonthEntriesProvider)
      .fold<double>(0, (sum, e) => sum + e.amount);
});

class CategoryTotal {
  const CategoryTotal(this.categoryId, this.amount);

  final String categoryId;
  final double amount;
}

/// Month spending per category, biggest first.
final personalCategoryTotalsProvider = Provider<List<CategoryTotal>>((ref) {
  final totals = <String, double>{};
  for (final e in ref.watch(personalMonthEntriesProvider)) {
    totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amount;
  }
  final list = [
    for (final entry in totals.entries) CategoryTotal(entry.key, entry.value),
  ]..sort((a, b) => b.amount.compareTo(a.amount));
  return list;
});

/// Monthly personal budget (0 = not set), saved on this phone.
class PersonalBudgetNotifier extends Notifier<double> {
  @override
  double build() => ref.watch(preferencesServiceProvider).personalBudget;

  Future<void> set(double value) async {
    await ref.read(preferencesServiceProvider).setPersonalBudget(value);
    state = value > 0 ? value : 0;
  }
}

final personalBudgetProvider =
    NotifierProvider<PersonalBudgetNotifier, double>(PersonalBudgetNotifier.new);

/// Personal bills and expenses still to pay (any month, newest first).
final personalPendingProvider = Provider<List<ExpenseModel>>((ref) {
  return ref
      .watch(personalEntriesProvider)
      .where((e) => e.isPending)
      .toList();
});
