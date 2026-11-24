import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/utils/date_utils.dart';
import 'package:pocket_karcha/core/utils/period_filter.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';

/// Shell tabs: 0 Home · 1 History · 2 Reports · 3 People · 4 More.
final mainTabIndexProvider = StateProvider<int>((ref) => 0);

abstract final class ShellTabs {
  static const home = 0;
  static const history = 1;
  static const reports = 2;
  static const people = 3;
  static const more = 4;
}

enum DashboardPeriod { day, week, month }

final dashboardPeriodProvider =
    StateProvider<DashboardPeriod>((ref) => DashboardPeriod.week);

double _sum(Iterable<ExpenseModel> items) =>
    items.fold<double>(0, (total, e) => total + e.amount);

// ── Selected period (day / week / month) ─────────────────────────────────

final periodTransactionsProvider = Provider<List<ExpenseModel>>((ref) {
  final all = ref.watch(expensesStreamProvider).valueOrNull ?? const [];
  final period = ref.watch(dashboardPeriodProvider);
  return filterExpensesByPeriod(all, period);
});

/// Sales / money in.
final periodSalesProvider = Provider<double>((ref) {
  return _sum(ref.watch(periodTransactionsProvider).where((e) => e.isIncome));
});

/// Stock & raw-material purchases.
final periodPurchasesProvider = Provider<double>((ref) {
  return _sum(ref.watch(periodTransactionsProvider).where((e) => e.isPurchase));
});

/// Running expenses (rent, bills, salary…).
final periodExpensesOnlyProvider = Provider<double>((ref) {
  return _sum(ref.watch(periodTransactionsProvider).where((e) => e.isExpense));
});

/// Total money out = purchases + expenses.
final periodTotalProvider = Provider<double>((ref) {
  return ref.watch(periodPurchasesProvider) +
      ref.watch(periodExpensesOnlyProvider);
});

/// Alias kept for older widgets — same as [periodSalesProvider].
final periodIncomeProvider = Provider<double>((ref) {
  return ref.watch(periodSalesProvider);
});

/// Profit (positive) or loss (negative) = sales − purchases − expenses.
final periodProfitProvider = Provider<double>((ref) {
  return ref.watch(periodSalesProvider) - ref.watch(periodTotalProvider);
});

/// Alias kept for older widgets — same as [periodProfitProvider].
final periodBalanceProvider = Provider<double>((ref) {
  return ref.watch(periodProfitProvider);
});

final dashboardRecentExpensesProvider = Provider<List<ExpenseModel>>((ref) {
  final list = List<ExpenseModel>.from(ref.watch(periodTransactionsProvider));
  list.sort((a, b) => b.date.compareTo(a.date));
  return list.take(6).toList();
});

// ── Monthly budget ────────────────────────────────────────────────────────

class MonthlyBudgetNotifier extends Notifier<double> {
  @override
  double build() => ref.read(preferencesServiceProvider).monthlyBudget;

  Future<void> set(double value) async {
    state = value < 0 ? 0 : value;
    await ref.read(preferencesServiceProvider).setMonthlyBudget(state);
  }

  Future<void> clear() => set(0);
}

/// Monthly spending limit for purchases + expenses (0 = not set).
final monthlyBudgetProvider =
    NotifierProvider<MonthlyBudgetNotifier, double>(MonthlyBudgetNotifier.new);

final currentMonthTransactionsProvider = Provider<List<ExpenseModel>>((ref) {
  final all = ref.watch(expensesStreamProvider).valueOrNull ?? const [];
  final now = DateTime.now();
  return all.where((e) => AppDateUtils.isSameMonth(e.date, now)).toList();
});

/// Purchases + expenses in the current calendar month.
final monthSpendingProvider = Provider<double>((ref) {
  return _sum(
    ref.watch(currentMonthTransactionsProvider).where((e) => e.isOutflow),
  );
});

class BudgetStatus {
  const BudgetStatus({
    required this.budget,
    required this.spent,
    required this.daysLeft,
  });

  final double budget;
  final double spent;

  /// Days left in this month, including today.
  final int daysLeft;

  bool get isSet => budget > 0;
  double get remaining => budget - spent;
  bool get isOver => isSet && spent > budget;
  double get usedFraction => isSet ? spent / budget : 0;
  int get usedPercent => (usedFraction * 100).round();

  /// How much can still be spent per day without crossing the budget.
  double get perDayAllowance =>
      remaining <= 0 || daysLeft <= 0 ? 0 : remaining / daysLeft;
}

final budgetStatusProvider = Provider<BudgetStatus>((ref) {
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  return BudgetStatus(
    budget: ref.watch(monthlyBudgetProvider),
    spent: ref.watch(monthSpendingProvider),
    daysLeft: daysInMonth - now.day + 1,
  );
});
