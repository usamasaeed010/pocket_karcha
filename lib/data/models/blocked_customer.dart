import 'package:pocket_karcha/data/models/firestore_parse.dart';

/// One doc in `stores/{ownerUid}/blocked/{key}`. firestore.rules refuses a
/// link order when its phone digits or buyer uid match a key. One block
/// writes several keys (every common way of writing the number, plus the
/// buyer's uid) that share a [group].
class BlockedEntry {
  const BlockedEntry({
    required this.key,
    required this.group,
    this.name = '',
    this.phone = '',
    this.createdAt,
  });

  final String key;
  final String group;
  final String name;
  final String phone;
  final DateTime? createdAt;

  factory BlockedEntry.fromMap(String key, Map<String, dynamic> m) =>
      BlockedEntry(
        key: key,
        group: FsParse.string(m['group'], key),
        name: FsParse.string(m['name']),
        phone: FsParse.string(m['phone']),
        createdAt: FsParse.date(m['createdAt']),
      );
}

/// A blocked customer as shown in Settings: all keys of one block.
class BlockedCustomer {
  const BlockedCustomer({
    required this.group,
    required this.name,
    required this.phone,
    required this.keys,
    this.createdAt,
  });

  final String group;
  final String name;
  final String phone;
  final List<String> keys;
  final DateTime? createdAt;

  /// Newest block first.
  static List<BlockedCustomer> fromEntries(List<BlockedEntry> entries) {
    final byGroup = <String, List<BlockedEntry>>{};
    for (final e in entries) {
      byGroup.putIfAbsent(e.group, () => []).add(e);
    }
    final list = [
      for (final g in byGroup.entries)
        BlockedCustomer(
          group: g.key,
          name: g.value
              .map((e) => e.name)
              .firstWhere((n) => n.isNotEmpty, orElse: () => ''),
          phone: g.value
              .map((e) => e.phone)
              .firstWhere((p) => p.isNotEmpty, orElse: () => ''),
          keys: [for (final e in g.value) e.key],
          createdAt: g.value.first.createdAt,
        ),
    ];
    list.sort((a, b) => (b.createdAt ?? DateTime(0))
        .compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  /// The keys to block for one customer. Orders from the page keep the
  /// phone as typed (digits only), so "0300…", "92300…", "0092300…" and
  /// "300…" are all blocked, plus the buyer's uid.
  static Set<String> keysFor({
    required String phone,
    String buyerUid = '',
    String dialCode = '+92',
  }) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final keys = <String>{if (buyerUid.isNotEmpty) buyerUid};
    if (digits.isEmpty) return keys;
    final national = nationalNumber(digits, dialCode: dialCode);
    final dial = dialCode.replaceAll(RegExp(r'\D'), '');
    keys.addAll({
      digits,
      national,
      '0$national',
      if (dial.isNotEmpty) '$dial$national',
      if (dial.isNotEmpty) '00$dial$national',
    });
    return keys;
  }

  /// "03001234567", "923001234567", "+92 300 1234567" → "3001234567".
  static String nationalNumber(String phone, {String dialCode = '+92'}) {
    var d = phone.replaceAll(RegExp(r'\D'), '');
    final dial = dialCode.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('00')) d = d.substring(2);
    if (dial.isNotEmpty && d.startsWith(dial) && d.length > dial.length + 6) {
      d = d.substring(dial.length);
    }
    while (d.startsWith('0')) {
      d = d.substring(1);
    }
    return d;
  }

  /// One block's group id: the national number, else the buyer uid.
  static String groupFor({
    required String phone,
    String buyerUid = '',
    String dialCode = '+92',
  }) {
    final national = nationalNumber(phone, dialCode: dialCode);
    return national.isNotEmpty ? national : buyerUid;
  }
}
