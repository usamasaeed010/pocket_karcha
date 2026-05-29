import 'package:intl/intl.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';

abstract final class AppDateUtils {
  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static String formatShort(DateTime date) =>
      DateFormat('d MMM').format(date);

  static String groupLabel(DateTime date, {required bool urdu}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return urdu ? 'آج' : 'Today';
    if (diff == 1) return urdu ? 'کل' : 'Yesterday';
    return DateFormat('d MMM yyyy').format(date);
  }

  static List<({String label, List<ExpenseModel> items})> groupByDate(
    List<ExpenseModel> expenses, {
    required bool urdu,
  }) {
    if (expenses.isEmpty) return [];

    final map = <String, List<ExpenseModel>>{};
    final order = <String>[];

    for (final e in expenses) {
      final key = '${e.date.year}-${e.date.month}-${e.date.day}';
      if (!map.containsKey(key)) {
        map[key] = [];
        order.add(key);
      }
      map[key]!.add(e);
    }

    return order.map((key) {
      final items = map[key]!;
      final label = groupLabel(items.first.date, urdu: urdu);
      return (label: label, items: items);
    }).toList();
  }
}
