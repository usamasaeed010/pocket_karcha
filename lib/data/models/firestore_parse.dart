import 'package:cloud_firestore/cloud_firestore.dart';

/// Lenient readers for Firestore maps. Web-created docs and app-created docs
/// can differ slightly (int vs double, missing optional fields).
abstract final class FsParse {
  static double number(dynamic v, [double fallback = 0]) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static int integer(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static String string(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    if (v is String) return v;
    return '$v';
  }

  static bool boolean(dynamic v, [bool fallback = false]) {
    if (v is bool) return v;
    return fallback;
  }

  static DateTime? date(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static Map<String, dynamic> map(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry('$k', val));
    return const {};
  }

  static List<Map<String, dynamic>> mapList(dynamic v) {
    if (v is! List) return const [];
    return v.map(map).where((m) => m.isNotEmpty).toList();
  }
}
