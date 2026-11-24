import 'package:intl/intl.dart';

/// "Rs 1,700" — decimals only when the amount has paise/cents.
String formatMoney(num value, String symbol) {
  final whole = value == value.roundToDouble();
  final f = NumberFormat.decimalPatternDigits(
    locale: 'en',
    decimalDigits: whole ? 0 : 2,
  );
  final sym = symbol.trim();
  return sym.isEmpty ? f.format(value) : '$sym ${f.format(value)}';
}

/// Plain number for input fields: 250 → "250", 2.5 → "2.5".
String formatPlainNumber(num value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

/// Lenient number parse for price fields ("1,200", "Rs 300").
double? parseAmount(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}
