import 'package:pocket_karcha/core/utils/date_utils.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';

List<ExpenseModel> filterExpensesByPeriod(
  List<ExpenseModel> expenses,
  DashboardPeriod period,
) {
  final now = DateTime.now();
  return expenses.where((e) {
    switch (period) {
      case DashboardPeriod.day:
        return e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day;
      case DashboardPeriod.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final startDay = DateTime(start.year, start.month, start.day);
        final endDay = startDay.add(const Duration(days: 7));
        return !e.date.isBefore(startDay) && e.date.isBefore(endDay);
      case DashboardPeriod.month:
        return AppDateUtils.isSameMonth(e.date, now);
    }
  }).toList();
}
