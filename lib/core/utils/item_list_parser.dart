/// One line of a pasted menu / price list.
class ParsedItem {
  const ParsedItem({required this.name, required this.price});

  final String name;
  final double? price;
}

/// Parses "Mango Shake - 250", "2. Zinger Burger Rs 450/-", "Fries: 150".
/// Lines without a price are kept with `price == null`.
abstract final class ItemListParser {
  static final _bullet = RegExp(r'^\s*(?:[-*•▪◦►]+|\d{1,3}[.)])\s*');
  static final _trailingPrice = RegExp(
    r'^(.*?)[\s:=\-–—,|@]*\s*(?:rs\.?|pkr|inr|₹|₨|\$|aed|sar)?\s*([0-9][0-9,]*(?:\.[0-9]+)?)\s*(?:/-|rs\.?|pkr|only)?\s*$',
    caseSensitive: false,
  );

  static List<ParsedItem> parse(String text) {
    final out = <ParsedItem>[];
    for (final raw in text.split(RegExp(r'\r?\n'))) {
      var line = raw.trim();
      if (line.isEmpty) continue;
      line = line.replaceFirst(_bullet, '').trim();
      if (line.isEmpty) continue;

      final m = _trailingPrice.firstMatch(line);
      if (m != null) {
        final name = _cleanName(m.group(1) ?? '');
        final price = double.tryParse((m.group(2) ?? '').replaceAll(',', ''));
        if (name.isNotEmpty) {
          out.add(ParsedItem(name: name, price: price));
          continue;
        }
      }
      final name = _cleanName(line);
      if (name.isNotEmpty) out.add(ParsedItem(name: name, price: null));
    }
    return out;
  }

  static String _cleanName(String s) {
    var n = s.trim();
    n = n.replaceAll(RegExp(r'[\s:=\-–—,|@]+$'), '');
    n = n.replaceAll(RegExp(r'\s{2,}'), ' ');
    if (n.length > 80) n = n.substring(0, 80);
    if (n.isEmpty) return n;
    return n[0].toUpperCase() + n.substring(1);
  }
}
