import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/utils/date_utils.dart';
import 'package:pocket_karcha/core/utils/period_filter.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';

enum HistorySort { newest, oldest, amountHigh, amountLow }

final historySearchQueryProvider = StateProvider<String>((ref) => '');

final historySortProvider =
    StateProvider<HistorySort>((ref) => HistorySort.newest);

final filteredHistoryExpensesProvider = Provider<List<ExpenseModel>>((ref) {
  final all = ref.watch(expensesStreamProvider).valueOrNull ?? [];
  final period = ref.watch(dashboardPeriodProvider);
  final query = ref.watch(historySearchQueryProvider).trim().toLowerCase();
  final sort = ref.watch(historySortProvider);

  var list = filterExpensesByPeriod(all, period);

  if (query.isNotEmpty) {
    list = list.where((e) {
      final cat = ref.read(categoryByIdProvider(e.categoryId));
      return e.note.toLowerCase().contains(query) ||
          cat.labelEn.toLowerCase().contains(query) ||
          cat.labelUr.contains(query);
    }).toList();
  }

  list = List<ExpenseModel>.from(list);
  switch (sort) {
    case HistorySort.newest:
      list.sort((a, b) => b.date.compareTo(a.date));
    case HistorySort.oldest:
      list.sort((a, b) => a.date.compareTo(b.date));
    case HistorySort.amountHigh:
      list.sort((a, b) => b.amount.compareTo(a.amount));
    case HistorySort.amountLow:
      list.sort((a, b) => a.amount.compareTo(b.amount));
  }

  return list;
});

final historyYouGaveProvider = Provider<double>((ref) {
  return ref
      .watch(filteredHistoryExpensesProvider)
      .where((e) => !e.isIncome)
      .fold<double>(0, (s, e) => s + e.amount);
});

final historyYouGotProvider = Provider<double>((ref) {
  return ref
      .watch(filteredHistoryExpensesProvider)
      .where((e) => e.isIncome)
      .fold<double>(0, (s, e) => s + e.amount);
});

final historyClosingBalanceProvider = Provider<double>((ref) {
  const opening = 0.0;
  final got = ref.watch(historyYouGotProvider);
  final gave = ref.watch(historyYouGaveProvider);
  return opening + got - gave;
});

final historyGroupedExpensesProvider =
    Provider<List<({String label, List<ExpenseModel> items})>>((ref) {
  final list = ref.watch(filteredHistoryExpensesProvider);
  final urdu = ref.watch(localeUrduProvider);
  return AppDateUtils.groupByDate(list, urdu: urdu);
});
