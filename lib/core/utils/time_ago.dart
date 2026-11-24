import 'package:intl/intl.dart';

abstract final class TimeAgo {
  /// "just now", "4m ago", "2h ago", "Yesterday", "3 Nov".
  static String short(DateTime time, {required bool urdu}) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return urdu ? 'ابھی' : 'just now';
    if (diff.inMinutes < 60) {
      return urdu ? '${diff.inMinutes} منٹ پہلے' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24 && _sameDay(time, DateTime.now())) {
      return urdu ? '${diff.inHours} گھنٹے پہلے' : '${diff.inHours}h ago';
    }
    if (_isYesterday(time)) return urdu ? 'کل' : 'Yesterday';
    final sameYear = time.year == DateTime.now().year;
    return DateFormat(sameYear ? 'd MMM' : 'd MMM yyyy').format(time);
  }

  /// "Today 4:07 PM", "Yesterday 9:10 AM", "3 Nov, 4:07 PM".
  static String dayAndTime(DateTime time, {required bool urdu}) {
    final clock = DateFormat('h:mm a').format(time);
    if (_sameDay(time, DateTime.now())) {
      return urdu ? 'آج $clock' : 'Today $clock';
    }
    if (_isYesterday(time)) return urdu ? 'کل $clock' : 'Yesterday $clock';
    return '${DateFormat('d MMM').format(time)}, $clock';
  }

  /// Section label for grouped lists.
  static String dayLabel(DateTime time, {required bool urdu}) {
    if (_sameDay(time, DateTime.now())) return urdu ? 'آج' : 'Today';
    if (_isYesterday(time)) return urdu ? 'کل' : 'Yesterday';
    final sameYear = time.year == DateTime.now().year;
    return DateFormat(sameYear ? 'EEE, d MMM' : 'd MMM yyyy').format(time);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isYesterday(DateTime t) =>
      _sameDay(t, DateTime.now().subtract(const Duration(days: 1)));
}
