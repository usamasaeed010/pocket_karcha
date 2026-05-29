import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/utils/period_filter.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';

final mainTabIndexProvider = StateProvider<int>((ref) => 0);

enum DashboardPeriod { day, week, month }

final dashboardPeriodProvider =
    StateProvider<DashboardPeriod>((ref) => DashboardPeriod.week);

/// Default monthly budget hint (PKR) — can move to Firestore later.
final monthlyBudgetProvider = StateProvider<double>((ref) => 50000);

List<ExpenseModel> _periodExpenses(Ref ref) {
  final all = ref.watch(expensesStreamProvider).valueOrNull ?? [];
  final period = ref.watch(dashboardPeriodProvider);
  return filterExpensesByPeriod(all, period);
}

final todayTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return expenses
      .where(
        (e) =>
            !e.isIncome &&
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day,
      )
      .fold<double>(0, (sum, e) => sum + e.amount);
});

final periodTotalProvider = Provider<double>((ref) {
  return _periodExpenses(ref)
      .where((e) => !e.isIncome)
      .fold<double>(0, (sum, e) => sum + e.amount);
});

final periodIncomeProvider = Provider<double>((ref) {
  return _periodExpenses(ref)
      .where((e) => e.isIncome)
      .fold<double>(0, (sum, e) => sum + e.amount);
});

final periodBalanceProvider = Provider<double>((ref) {
  return ref.watch(periodIncomeProvider) - ref.watch(periodTotalProvider);
});

final dashboardRecentExpensesProvider = Provider<List<ExpenseModel>>((ref) {
  final list = List<ExpenseModel>.from(_periodExpenses(ref));
  list.sort((a, b) => b.date.compareTo(a.date));
  return list.take(6).toList();
});

final budgetUsageProvider = Provider<double>((ref) {
  final budget = ref.watch(monthlyBudgetProvider);
  if (budget <= 0) return 0;
  final spent = ref.watch(monthTotalProvider);
  return (spent / budget * 100).clamp(0, 100);
});
