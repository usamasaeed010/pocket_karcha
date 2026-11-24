/// Units a shop owner buys or sells in (kg, dozen, crate/peti, glass…).
class StockUnit {
  const StockUnit({
    required this.key,
    required this.shortEn,
    required this.nameEn,
    required this.nameUr,
  });

  /// Stored value, e.g. `dozen`.
  final String key;

  /// Compact label for lists, e.g. `pc`.
  final String shortEn;

  /// Full label for pickers, e.g. `crate / peti`.
  final String nameEn;
  final String nameUr;

  String short(bool urdu) => urdu ? nameUr : shortEn;
  String name(bool urdu) => urdu ? nameUr : nameEn;
}

abstract final class StockUnits {
  static const List<StockUnit> all = [
    StockUnit(key: 'kg', shortEn: 'kg', nameEn: 'kg', nameUr: 'کلو'),
    StockUnit(key: 'g', shortEn: 'g', nameEn: 'gram', nameUr: 'گرام'),
    StockUnit(
      key: 'mann',
      shortEn: 'mann',
      nameEn: 'mann (40 kg)',
      nameUr: 'من',
    ),
    StockUnit(key: 'dozen', shortEn: 'dozen', nameEn: 'dozen', nameUr: 'درجن'),
    StockUnit(key: 'piece', shortEn: 'pc', nameEn: 'piece', nameUr: 'عدد'),
    StockUnit(key: 'litre', shortEn: 'L', nameEn: 'litre', nameUr: 'لیٹر'),
    StockUnit(key: 'packet', shortEn: 'pkt', nameEn: 'packet', nameUr: 'پیکٹ'),
    StockUnit(key: 'box', shortEn: 'box', nameEn: 'box / carton', nameUr: 'ڈبہ'),
    StockUnit(
      key: 'crate',
      shortEn: 'crate',
      nameEn: 'crate / peti',
      nameUr: 'پیٹی',
    ),
    StockUnit(key: 'bag', shortEn: 'bag', nameEn: 'bag / bori', nameUr: 'بوری'),
    StockUnit(key: 'tray', shortEn: 'tray', nameEn: 'tray', nameUr: 'ٹرے'),
    StockUnit(key: 'bottle', shortEn: 'btl', nameEn: 'bottle', nameUr: 'بوتل'),
    StockUnit(key: 'glass', shortEn: 'glass', nameEn: 'glass', nameUr: 'گلاس'),
    StockUnit(key: 'plate', shortEn: 'plate', nameEn: 'plate', nameUr: 'پلیٹ'),
  ];

  static const String defaultPurchase = 'kg';
  static const String defaultSale = 'piece';

  static StockUnit byKey(String? key) {
    for (final u in all) {
      if (u.key == key) return u;
    }
    final fallback = (key == null || key.isEmpty) ? 'piece' : key;
    return StockUnit(
      key: fallback,
      shortEn: fallback,
      nameEn: fallback,
      nameUr: fallback,
    );
  }

  /// `12` → "12", `2.5` → "2.5", `0.250` → "0.25".
  static String formatQty(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    var text = value.toStringAsFixed(3);
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    return text;
  }
}
