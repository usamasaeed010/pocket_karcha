import 'dart:math' as math;

import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/data/models/person_model.dart';
import 'package:pocket_karcha/data/models/product_model.dart';

/// One menu line heard in a voice entry, e.g. 1 × Dahi Bhalla (Half).
class VoiceSaleLine {
  const VoiceSaleLine({
    required this.heard,
    this.product,
    this.variant,
    this.qty = 1,
    this.alternatives = const [],
  });

  /// The words this line came from, e.g. "1 dahi bhalla half".
  final String heard;

  /// Menu item, or null when the words matched nothing on the menu.
  final ProductModel? product;

  /// Chosen size. Null when the item has no sizes or none was said.
  final ProductVariant? variant;
  final int qty;

  /// Other menu items that matched almost as well.
  final List<ProductModel> alternatives;

  bool get isMatched => product != null;

  /// The item has sizes (e.g. Half / Full) but none was said.
  bool get needsSize =>
      product != null && product!.hasVariants && variant == null;

  bool get isReady => isMatched && !needsSize;

  double get unitPrice {
    final p = product;
    if (p == null) return 0;
    if (variant != null) return variant!.price;
    return p.hasVariants ? 0 : p.price;
  }

  double get total => unitPrice * qty;

  /// "Dahi Bhalla (Half)".
  String get label {
    final p = product;
    if (p == null) return heard;
    return variant == null ? p.name : '${p.name} (${variant!.name})';
  }

  VoiceSaleLine copyWith({
    ProductModel? product,
    ProductVariant? variant,
    bool clearVariant = false,
    int? qty,
  }) {
    final newProduct = product ?? this.product;
    var newVariant = clearVariant ? null : (variant ?? this.variant);
    // A size of another item never carries over.
    if (product != null && product.id != this.product?.id && variant == null) {
      newVariant = product.variants.length == 1 ? product.variants.first : null;
    }
    return VoiceSaleLine(
      heard: heard,
      product: newProduct,
      variant: newVariant,
      qty: qty ?? this.qty,
      alternatives: product != null ? const [] : alternatives,
    );
  }
}

/// What a voice entry said: menu lines, whose name it goes on, and whether
/// it was paid.
class VoiceSaleDraft {
  const VoiceSaleDraft({
    this.lines = const [],
    this.personName,
    this.person,
    this.status,
  });

  final List<VoiceSaleLine> lines;

  /// Name as said ("Usama"), when the entry goes on someone's khata.
  final String? personName;

  /// Existing person that matches [personName].
  final PersonModel? person;

  /// Paid / pending when it was said ("cash", "udhaar"); null otherwise.
  final EntryStatus? status;

  bool get isEmpty => lines.isEmpty;

  int get matchedCount => lines.where((l) => l.isMatched).length;

  double get total =>
      lines.fold(0, (sum, l) => sum + (l.isReady ? l.total : 0));

  /// How well the words fit the menu — used to pick the best of the
  /// speech recognizer's guesses.
  double get quality =>
      matchedCount * 2.0 -
      (lines.length - matchedCount) -
      lines.where((l) => l.needsSize).length * 0.3 +
      (person != null ? 0.6 : (personName != null ? 0.3 : 0));
}

/// Turns a spoken (or typed) sale into menu lines, e.g.
/// "1 dahi bhalla half add kar do Usama ke naam pe" →
/// 1 × Dahi Bhalla (Half), on Usama's khata.
///
/// Works with Roman Urdu / English and Urdu script. Item, size and person
/// names are matched loosely, because speech and spelling vary
/// ("bhalla", "bhalle", "بھلے").
abstract final class VoiceSaleParser {
  /// Reads [text] against the [menu] and the lena-dena [people].
  static VoiceSaleDraft parse(
    String text, {
    required List<ProductModel> menu,
    List<PersonModel> people = const [],
  }) {
    final tokens = _tokenize(text);
    if (tokens.isEmpty) return const VoiceSaleDraft();
    final entries = [
      for (final p in menu)
        if (p.name.trim().isNotEmpty) _MenuEntry(p),
    ];
    final status = _statusOf(tokens);

    // 1. Whose name it goes on.
    final found = _findPerson(tokens, entries, people);
    var rest = tokens;
    String? personName;
    if (found != null) {
      personName = found.name;
      rest = [
        ...tokens.sublist(0, found.start),
        ...tokens.sublist(found.end + 1),
      ];
    }

    // 2. Menu lines.
    final built = _buildLines(_classify(rest), entries);

    // 3. A lone name with no "ke naam" ("Usama, 2 samose") still counts
    //    when it is someone already in lena-dena.
    PersonModel? person =
        personName != null ? _matchPerson(personName, people) : null;
    if (personName == null && people.isNotEmpty) {
      for (var i = 0; i < built.length; i++) {
        final b = built[i];
        if (b.product != null || b.words.isEmpty || b.words.length > 2) {
          continue;
        }
        final match = _matchPerson(b.words.join(' '), people, min: 0.85);
        if (match != null) {
          person = match;
          personName = match.name;
          built.removeAt(i);
          break;
        }
      }
    }

    return VoiceSaleDraft(
      lines: [for (final b in built) b.toLine()],
      personName: personName,
      person: person,
      status: status,
    );
  }

  /// Best reading among several guesses of the same speech.
  static ({String text, VoiceSaleDraft draft}) parseBest(
    List<String> texts, {
    required List<ProductModel> menu,
    List<PersonModel> people = const [],
  }) {
    var bestText = texts.isEmpty ? '' : texts.first;
    VoiceSaleDraft? best;
    for (final t in texts) {
      final d = parse(t, menu: menu, people: people);
      if (best == null || d.quality > best.quality + 0.001) {
        best = d;
        bestText = t;
      }
    }
    return (text: bestText, draft: best ?? const VoiceSaleDraft());
  }

  // ── Words ──────────────────────────────────────────────────────────────

  static const _separators = {
    ',', 'aur', 'or', 'and', 'plus', 'phir', 'then', 'also', 'اور', 'نیز',
  };

  static const _numberWords = <String, int>{
    'ek': 1, 'aik': 1, 'ik': 1, 'one': 1, 'ایک': 1, 'اک': 1,
    'do': 2, 'two': 2, 'دو': 2,
    'teen': 3, 'tin': 3, 'three': 3, 'تین': 3,
    'char': 4, 'chaar': 4, 'four': 4, 'چار': 4,
    'panch': 5, 'paanch': 5, 'panj': 5, 'five': 5, 'پانچ': 5,
    'chhe': 6, 'chhay': 6, 'chay': 6, 'che': 6, 'chey': 6, 'six': 6,
    'چھ': 6, 'چھے': 6, 'چھہ': 6,
    'saat': 7, 'sat': 7, 'seven': 7, 'سات': 7,
    'aath': 8, 'ath': 8, 'eight': 8, 'آٹھ': 8,
    'nau': 9, 'nine': 9, 'نو': 9,
    'das': 10, 'dus': 10, 'ten': 10, 'دس': 10,
    'gyarah': 11, 'giarah': 11, 'eleven': 11, 'گیارہ': 11,
    'barah': 12, 'baarah': 12, 'twelve': 12, 'بارہ': 12,
    'pandrah': 15, 'fifteen': 15, 'پندرہ': 15,
    'bees': 20, 'twenty': 20, 'بیس': 20,
  };

  /// Words before "do" that make it the verb ("kar do"), not two.
  static const _verbsBeforeDo = {
    'kar', 'kr', 'likh', 'daal', 'dal', 'de', 'add', 'ad', 'bata', 'bhej',
    'rakh', 'jor', 'jod', 'کر', 'لکھ', 'ڈال', 'دے', 'ایڈ', 'رکھ', 'جوڑ',
  };

  static const _unitWords = {
    'plate', 'plates', 'plt', 'piece', 'pieces', 'pc', 'pcs', 'adad',
    'glass', 'glasses', 'cup', 'cups', 'packet', 'packets', 'pkt', 'box',
    'bottle', 'bottles', 'dabba', 'kilo', 'kg', 'darjan', 'dozen',
    'پلیٹ', 'پیس', 'عدد', 'گلاس', 'کپ', 'پیکٹ', 'ڈبہ', 'بوتل', 'کلو', 'درجن',
  };

  static const _possessive = {
    'ke', 'k', 'ka', 'kay', 'ky', 'ki', 'kai', 'kae', 'kee', 'kaa',
    'کے', 'کا', 'کی',
  };
  static const _nameWords = {'naam', 'nam', 'name', 'naame', 'نام'};
  static const _ledgerWords = {
    'khate', 'khaate', 'khata', 'khaata', 'khatay', 'khaatay', 'khatey',
    'account', 'hisab', 'hisaab', 'کھاتے', 'کھاتہ', 'کھاتا', 'حساب', 'اکاؤنٹ',
  };
  static const _forWords = {
    'liye', 'lie', 'liay', 'lye', 'leye', 'liya', 'لیے', 'لئے', 'لیئے',
  };
  static const _postpositions = {
    'pe', 'par', 'pr', 'py', 'per', 'pay', 'pai', 'mein', 'me', 'main',
    'mai', 'mn', 'se', 'sy', 'پے', 'پر', 'میں', 'سے',
  };
  static const _honorifics = {
    'bhai', 'bhaee', 'bhaijan', 'bhaijaan', 'bhaiya', 'bhayya', 'sahab',
    'sahib', 'saab', 'sb', 'ji', 'jee', 'uncle', 'aunty', 'anti', 'baji',
    'baaji', 'madam', 'sir', 'بھائی', 'صاحب', 'جی', 'انکل', 'باجی',
  };

  static const _currencyWords = {
    'rs', 'rupay', 'rupaye', 'rupee', 'rupees', 'rupya', 'rupiya',
    'روپے', 'روپیہ', 'روپیے',
  };

  static const _pendingWords = {
    'udhaar', 'udhar', 'udhaari', 'udhari', 'baqi', 'baki', 'baaki',
    'pending', 'credit', 'ادھار', 'باقی',
  };
  static const _paidWords = {
    'cash', 'naqd', 'nakad', 'naqad', 'nagad', 'paid', 'نقد', 'کیش',
  };

  static const _stopWords = {
    // Commands and helpers.
    'add', 'ad', 'kar', 'kr', 'karo', 'kro', 'kardo', 'krdo', 'karna',
    'krna', 'karen', 'karein', 'kariye', 'kijiye', 'likh', 'likho',
    'likhdo', 'likhna', 'likhen', 'likhein', 'daal', 'dal', 'daalo', 'dalo',
    'daldo', 'de', 'dedo', 'dy', 'dena', 'dain', 'den', 'diya', 'diye',
    'di', 'dia', 'gaya', 'gya', 'gayi', 'gai', 'liya', 'lo', 'le', 'rakh',
    'rakho', 'jor', 'jod', 'jodo', 'joro', 'hai', 'ha', 'he', 'hain', 'hy',
    'tha', 'thi', 'please', 'plz', 'pls', 'zara', 'bhi', 'ko', 'wala',
    'wali', 'wale', 'waala', 'waali', 'waale', 'vala', 'vali', 'order',
    'entry', 'sale', 'sell', 'becha', 'bechi', 'beche', 'x', 'times',
    'the', 'a', 'an', 'of', 'to', 'for', 'with', 'is', 'it', 'on', 'in',
    'customer', 'mujhe', 'humein', 'abhi', 'jaldi', 'bas', 'ok', 'okay',
    'theek', 'acha', 'achha', 'aik', 'paise', 'paisay', 'payment', 'ada',
    'mil', 'mile', 'gaye',
    // Urdu script.
    'ایڈ', 'کر', 'کرو', 'کردو', 'کریں', 'کرنا', 'لکھ', 'لکھو', 'لکھدو',
    'لکھیں', 'ڈال', 'ڈالو', 'ڈالدو', 'دے', 'دیں', 'دیا', 'دیے', 'دی', 'دیدو',
    'دینا', 'ہے', 'ہیں', 'تھا', 'پلیز', 'بھی', 'کو', 'والا', 'والی', 'والے',
    'آرڈر', 'گیا', 'گئی', 'لیا', 'رکھ', 'رکھو', 'جوڑ', 'جوڑو', 'ابھی', 'بس',
    'پیسے', 'ادا',
  };

  static const _sizeGroups = <String, List<String>>{
    'half': [
      'half', 'haaf', 'haf', 'aadha', 'adha', 'aadhi', 'adhi', 'adhaa',
      'ہاف', 'ہالف', 'آدھا', 'آدھی', 'ادھا',
    ],
    'full': [
      'full', 'ful', 'fool', 'fuul', 'pura', 'poora', 'puri', 'poori',
      'فل', 'فول', 'پورا', 'پوری',
    ],
    'quarter': ['quarter', 'pao', 'pav', 'paav', 'paow', 'کوارٹر', 'پاؤ', 'پاو'],
    'small': [
      'small', 'chota', 'chhota', 'choti', 'chhoti', 'chotta', 'سمال',
      'چھوٹا', 'چھوٹی', 'چھوٹے',
    ],
    'medium': ['medium', 'darmiyana', 'darmiyani', 'میڈیم', 'درمیانہ', 'درمیانی'],
    'large': [
      'large', 'big', 'bara', 'bada', 'bari', 'badi', 'barra', 'لارج', 'بڑا',
      'بڑی', 'بڑے',
    ],
    'regular': ['regular', 'normal', 'sada', 'saada', 'ریگولر', 'نارمل', 'سادہ'],
    'single': ['single', 'singal', 'سنگل'],
    'double': ['double', 'dabal', 'dubble', 'ڈبل'],
    'family': ['family', 'فیملی'],
  };

  static final Map<String, String> _sizeWordToGroup = {
    for (final e in _sizeGroups.entries)
      for (final w in e.value) w: e.key,
  };

  static String? _sizeGroupOf(String token) => _sizeWordToGroup[token];

  /// Size group a menu size belongs to: "Half Plate" → half.
  static String? _groupOfVariant(ProductVariant v) {
    for (final w in _tokenize(v.name)) {
      final g = _sizeWordToGroup[w];
      if (g != null) return g;
    }
    return null;
  }

  // ── Tokens ─────────────────────────────────────────────────────────────

  static List<String> _tokenize(String text) {
    var t = text.toLowerCase();
    // Urdu / Arabic digits → 0-9.
    t = t.replaceAllMapped(RegExp('[۰-۹٠-٩]'), (m) {
      final c = m[0]!.codeUnitAt(0);
      final base = c >= 0x06F0 ? 0x06F0 : 0x0660;
      return String.fromCharCode(0x30 + c - base);
    });
    t = t.replaceAll(RegExp(r'[,،;؛\n+&]'), ' , ');
    t = t.replaceAll(RegExp(r'[.!?؟۔:"“”‘’()\[\]{}*/\\-]'), ' ');
    // "2samose" → "2 samose".
    t = t.replaceAllMapped(
      RegExp(r'(\d)([^\d\s,])'),
      (m) => '${m[1]} ${m[2]}',
    );
    return t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  static EntryStatus? _statusOf(List<String> tokens) {
    EntryStatus? status;
    for (final t in tokens) {
      if (_pendingWords.contains(t)) status = EntryStatus.pending;
      if (_paidWords.contains(t)) status = EntryStatus.paid;
    }
    return status;
  }

  static int? _qtyAt(List<String> tokens, int i) {
    final t = tokens[i];
    final next = i + 1 < tokens.length ? tokens[i + 1] : null;
    // "150 rupay" is a price, not a count.
    if (next != null && _currencyWords.contains(next)) return null;
    final n = int.tryParse(t);
    if (n != null) return n >= 1 && n <= 999 ? n : null;
    final v = _numberWords[t];
    if (v == null) return null;
    if (t == 'do' || t == 'دو') {
      final prev = i > 0 ? tokens[i - 1] : null;
      if (prev != null && _verbsBeforeDo.contains(prev)) return null;
      // "... kar do" at the end, or "do" before a helper word.
      if (next == null || _separators.contains(next)) return null;
      if (_isHelper(next) && !_unitWords.contains(next)) return null;
    }
    return v;
  }

  static bool _isHelper(String t) =>
      _stopWords.contains(t) ||
      _unitWords.contains(t) ||
      _possessive.contains(t) ||
      _postpositions.contains(t) ||
      _honorifics.contains(t) ||
      _nameWords.contains(t) ||
      _ledgerWords.contains(t) ||
      _forWords.contains(t) ||
      _pendingWords.contains(t) ||
      _paidWords.contains(t);

  static List<_Tok> _classify(List<String> tokens) {
    return [
      for (var i = 0; i < tokens.length; i++)
        () {
          final t = tokens[i];
          if (_separators.contains(t)) return _Tok(t, _Kind.sep);
          final q = _qtyAt(tokens, i);
          if (q != null) return _Tok(t, _Kind.qty, qty: q);
          final g = _sizeGroupOf(t);
          if (g != null) return _Tok(t, _Kind.size, size: g);
          if (_isHelper(t) ||
              _currencyWords.contains(t) ||
              _numberWords.containsKey(t) ||
              int.tryParse(t) != null) {
            return _Tok(t, _Kind.stop);
          }
          return _Tok(t, _Kind.word);
        }(),
    ];
  }

  // ── Person ─────────────────────────────────────────────────────────────

  static bool _hasLetter(String t) =>
      RegExp(r'[a-z؀-ۿ]').hasMatch(t);

  static bool _isNameToken(String t, List<_MenuEntry> menu) {
    if (!_hasLetter(t)) return false;
    if (_separators.contains(t) || _isHelper(t)) return false;
    if (_currencyWords.contains(t)) return false;
    if (_numberWords.containsKey(t) || int.tryParse(t) != null) return false;
    if (_sizeGroupOf(t) != null) return false;
    for (final e in menu) {
      for (final w in e.words) {
        if (VoiceText.wordSim(t, w) >= 0.8) return false;
      }
    }
    return true;
  }

  static _FoundPerson? _findPerson(
    List<String> tokens,
    List<_MenuEntry> menu,
    List<PersonModel> people,
  ) {
    // Name before the marker: "Usama ke naam pe", "Usama bhai ke khate
    // mein", "Usama ke liye", "Usama ko".
    _FoundPerson? backward(int markerStart, int markerEnd) {
      final name = <String>[];
      final at = <int>[];
      var k = markerStart - 1;
      while (k >= 0 && name.length < 3) {
        final t = tokens[k];
        if (_honorifics.contains(t)) {
          k--;
          continue;
        }
        if (!_isNameToken(t, menu)) break;
        name.insert(0, t);
        at.insert(0, k);
        k--;
      }
      // "1 pakora Ali ke naam": the word right after a count is the item.
      final afterCount = k >= 0 &&
          (_numberWords.containsKey(tokens[k]) || int.tryParse(tokens[k]) != null);
      if (afterCount && name.length > 1) {
        name.removeAt(0);
        at.removeAt(0);
      }
      if (name.isEmpty) return null;
      return _FoundPerson(VoiceText.displayName(name), at.first, markerEnd);
    }

    // Name after the marker: "for Usama", "naam Usama".
    _FoundPerson? forward(int markerStart) {
      final name = <String>[];
      var k = markerStart + 1;
      while (k < tokens.length && name.length < 3) {
        final t = tokens[k];
        if (_honorifics.contains(t) && name.isNotEmpty) {
          k++;
          continue;
        }
        if (!_isNameToken(t, menu)) break;
        name.add(t);
        k++;
      }
      if (name.isEmpty) return null;
      return _FoundPerson(VoiceText.displayName(name), markerStart, k - 1);
    }

    // 1. "ke naam (pe)", "ke khate (mein)", "ke liye".
    for (var i = 0; i + 1 < tokens.length; i++) {
      final next = tokens[i + 1];
      if (!_possessive.contains(tokens[i])) continue;
      if (!_nameWords.contains(next) &&
          !_ledgerWords.contains(next) &&
          !_forWords.contains(next)) {
        continue;
      }
      var end = i + 1;
      if (end + 1 < tokens.length && _postpositions.contains(tokens[end + 1])) {
        end++;
      }
      final found = backward(i, end);
      if (found != null) return found;
    }
    // 2. "Usama ko".
    for (var i = 1; i < tokens.length; i++) {
      if (tokens[i] != 'ko' && tokens[i] != 'کو') continue;
      final found = backward(i, i);
      if (found != null) return found;
    }
    // 3. "for Usama", "naam Usama", "customer Usama".
    for (var i = 0; i + 1 < tokens.length; i++) {
      final t = tokens[i];
      final named = _nameWords.contains(t) &&
          (i == 0 || !_possessive.contains(tokens[i - 1]));
      if (t != 'for' && t != 'customer' && !named) continue;
      final found = forward(i);
      if (found != null) return found;
    }
    // 4. "Usama ka 1 dahi bhalla" — near the start, or someone known.
    for (var i = 1; i < tokens.length; i++) {
      if (!_possessive.contains(tokens[i])) continue;
      final found = backward(i, i);
      if (found == null) continue;
      if (i <= 3 || _matchPerson(found.name, people) != null) return found;
    }
    return null;
  }

  static PersonModel? _matchPerson(
    String name,
    List<PersonModel> people, {
    double min = 0.8,
  }) {
    PersonModel? best;
    var bestScore = 0.0;
    for (final p in people) {
      final full = VoiceText.phraseSim(name, p.name);
      final parts = p.name.trim().split(RegExp(r'\s+'));
      final first = parts.length > 1
          ? VoiceText.phraseSim(name, parts.first) * 0.97
          : 0.0;
      final score = math.max(full, first);
      if (score > bestScore + 0.001) {
        best = p;
        bestScore = score;
      }
    }
    return bestScore >= min ? best : null;
  }

  // ── Lines ──────────────────────────────────────────────────────────────

  static List<_Built> _buildLines(List<_Tok> toks, List<_MenuEntry> menu) {
    // Split at "aur" / commas, and where a new number starts.
    final raw = <_RawLine>[];
    var cur = _RawLine();
    var afterSep = false;
    void flush() {
      if (!cur.isEmpty) raw.add(cur);
      cur = _RawLine();
    }

    for (var i = 0; i < toks.length; i++) {
      final t = toks[i];
      if (t.kind == _Kind.sep) {
        flush();
        afterSep = true;
        continue;
      }
      if (t.kind == _Kind.stop) continue;
      if (t.kind == _Kind.qty &&
          (cur.words.isNotEmpty || cur.sizes.isNotEmpty || cur.qty != null)) {
        flush();
      }
      if (cur.isEmpty) {
        cur.afterSep = afterSep;
        afterSep = false;
      }
      switch (t.kind) {
        case _Kind.qty:
          cur.qty = t.qty;
        case _Kind.size:
          cur.sizes.add(_Pos(t, i));
        case _Kind.word:
          cur.words.add(_Pos(t, i));
        case _Kind.sep:
        case _Kind.stop:
          break;
      }
      cur.heard.add(t.text);
    }
    flush();

    final built = <_Built>[];
    for (final line in raw) {
      if (line.words.isEmpty) {
        _attachBare(line, built);
        continue;
      }
      final matches = _matchAll(line.words, menu);
      if (matches.isEmpty) {
        built.add(_Built(
          heard: line.heard.join(' '),
          words: [for (final w in line.words) w.tok.text],
          qty: line.qty ?? 1,
          explicitQty: line.qty != null,
        ));
        continue;
      }
      // Words outside every match may name a size ("beef", "1 kg").
      final used = <int>{
        for (final m in matches)
          for (var k = m.start; k <= m.end; k++) line.words[k].pos,
      };
      final leftovers = [
        for (final w in line.words)
          if (!used.contains(w.pos)) w.tok.text,
      ];
      final sizesFor = <int, List<_Tok>>{};
      for (final s in line.sizes) {
        var bestIdx = 0;
        var bestDist = double.infinity;
        for (var m = 0; m < matches.length; m++) {
          final startPos = line.words[matches[m].start].pos;
          final endPos = line.words[matches[m].end].pos;
          final dist = s.pos > endPos
              ? (s.pos - endPos).toDouble()
              : (startPos - s.pos) + 0.5;
          if (dist < bestDist) {
            bestDist = dist;
            bestIdx = m;
          }
        }
        (sizesFor[bestIdx] ??= []).add(s.tok);
      }
      for (var m = 0; m < matches.length; m++) {
        final match = matches[m];
        final sizes = sizesFor[m] ?? const <_Tok>[];
        built.add(_Built(
          heard: line.heard.join(' '),
          product: match.entry.product,
          variant: _pickVariant(match.entry.product, sizes, leftovers),
          sizeSaid: sizes.isNotEmpty,
          qty: m == 0 ? (line.qty ?? 1) : 1,
          explicitQty: m == 0 && line.qty != null,
          alternatives: match.alternatives,
        ));
      }
    }
    return built;
  }

  /// A line with no item words: "… half, aur 2 full" (same item again) or
  /// "dahi bhalla 2" (the count of the line before).
  static void _attachBare(_RawLine line, List<_Built> built) {
    if (built.isEmpty) return;
    final prev = built.last;
    final product = prev.product;
    if (product == null) {
      if (!prev.explicitQty && line.qty != null && line.sizes.isEmpty) {
        built[built.length - 1] = prev.copyWith(qty: line.qty, explicit: true);
      }
      return;
    }
    final sizes = [for (final s in line.sizes) s.tok];
    final fillsGap = !line.afterSep &&
        (line.qty == null || !prev.explicitQty) &&
        (sizes.isEmpty || !prev.sizeSaid);
    if (fillsGap) {
      built[built.length - 1] = prev.copyWith(
        qty: line.qty,
        explicit: line.qty != null,
        variant: sizes.isNotEmpty ? _pickVariant(product, sizes, const []) : null,
        sizeSaid: sizes.isNotEmpty,
      );
      return;
    }
    built.add(_Built(
      heard: line.heard.join(' '),
      product: product,
      variant: _pickVariant(product, sizes, const []),
      sizeSaid: sizes.isNotEmpty,
      qty: line.qty ?? 1,
      explicitQty: line.qty != null,
    ));
  }

  static ProductVariant? _pickVariant(
    ProductModel p,
    List<_Tok> sizes,
    List<String> leftovers,
  ) {
    if (!p.hasVariants) return null;
    for (final s in sizes) {
      final inGroup =
          p.variants.where((v) => _groupOfVariant(v) == s.size).toList();
      if (inGroup.length == 1) return inGroup.first;
      if (inGroup.length > 1) {
        return _bestVariantByWords(inGroup, leftovers) ?? inGroup.first;
      }
    }
    final words = [...leftovers, for (final s in sizes) s.text];
    final byWords = _bestVariantByWords(p.variants, words);
    if (byWords != null) return byWords;
    return p.variants.length == 1 ? p.variants.first : null;
  }

  static ProductVariant? _bestVariantByWords(
    List<ProductVariant> variants,
    List<String> words,
  ) {
    ProductVariant? best;
    var bestScore = 0.0;
    for (final v in variants) {
      for (final vw in _tokenize(v.name)) {
        for (final w in words) {
          final s = VoiceText.wordSim(w, vw);
          if (s > bestScore) {
            bestScore = s;
            best = v;
          }
        }
      }
    }
    return bestScore >= 0.8 ? best : null;
  }

  /// Every menu item named in [words], left to right.
  static List<_Match> _matchAll(List<_Pos> words, List<_MenuEntry> menu) {
    if (words.isEmpty || menu.isEmpty) return const [];
    _Match? best;
    for (var s = 0; s < words.length; s++) {
      for (var e = s; e < math.min(words.length, s + 5); e++) {
        final window = [for (var k = s; k <= e; k++) words[k].tok.text];
        for (final entry in menu) {
          final score = entry.score(window);
          final better = best == null ||
              score > best.score + 0.001 ||
              ((score - best.score).abs() <= 0.001 &&
                  (e - s) > (best.end - best.start));
          if (better && score >= _MenuEntry.minScore) {
            best = _Match(entry, s, e, score);
          }
        }
      }
    }
    if (best == null) return const [];
    final top = best;
    var alternatives = const <ProductModel>[];
    if (top.score < 0.95) {
      final window = [for (var k = top.start; k <= top.end; k++) words[k].tok.text];
      final close = <(ProductModel, double)>[
        for (final entry in menu)
          if (entry != top.entry)
            (entry.product, entry.score(window)),
      ]
          .where((e) => e.$2 >= _MenuEntry.minScore && e.$2 >= top.score - 0.08)
          .toList()
        ..sort((a, b) => b.$2.compareTo(a.$2));
      alternatives = [for (final e in close.take(3)) e.$1];
    }
    return [
      ..._matchAll(words.sublist(0, top.start), menu),
      _Match(top.entry, top.start, top.end, top.score, alternatives),
      ..._matchAll(words.sublist(top.end + 1), menu)
          .map((m) => m.shift(top.end + 1)),
    ];
  }
}

/// Loose text matching for speech: Urdu script is read as Roman, and
/// vowels / doubled letters / "h" count for little ("bhalla" ≈ "bhalle"
/// ≈ "بھلے").
abstract final class VoiceText {
  static const _urdu = <String, String>{
    'ا': 'a', 'آ': 'a', 'أ': 'a', 'إ': 'i', 'ب': 'b', 'پ': 'p', 'ت': 't',
    'ٹ': 't', 'ث': 's', 'ج': 'j', 'چ': 'ch', 'ح': 'h', 'خ': 'kh', 'د': 'd',
    'ڈ': 'd', 'ذ': 'z', 'ر': 'r', 'ڑ': 'r', 'ز': 'z', 'ژ': 'zh', 'س': 's',
    'ش': 'sh', 'ص': 's', 'ض': 'z', 'ط': 't', 'ظ': 'z', 'ع': 'a', 'غ': 'gh',
    'ف': 'f', 'ق': 'q', 'ک': 'k', 'ك': 'k', 'گ': 'g', 'ل': 'l', 'م': 'm',
    'ن': 'n', 'ں': 'n', 'و': 'o', 'ؤ': 'o', 'ہ': 'h', 'ه': 'h', 'ھ': 'h',
    'ۃ': 'a', 'ة': 'a', 'ء': '', 'ئ': 'i', 'ی': 'i', 'ي': 'i', 'ى': 'i',
    'ے': 'e', 'ۓ': 'e', 'ۂ': 'a',
  };

  /// Urdu script → rough Roman; Roman text is only lower-cased.
  static String roman(String text) {
    final s = text.toLowerCase().replaceAll(RegExp('[ً-ٰٟ]'), '');
    if (!RegExp('[؀-ۿ]').hasMatch(s)) return s;
    final out = StringBuffer();
    final chars = s.split('');
    for (var i = 0; i < chars.length; i++) {
      final c = chars[i];
      final mapped = _urdu[c];
      if (mapped == null) {
        out.write(c);
        continue;
      }
      final atStart = i == 0 || chars[i - 1] == ' ';
      final atEnd = i == chars.length - 1 || chars[i + 1] == ' ';
      if ((c == 'و') && atStart) {
        out.write('v');
      } else if ((c == 'ی' || c == 'ي') && atStart) {
        out.write('y');
      } else if ((c == 'ہ' || c == 'ه') && atEnd && !atStart) {
        out.write('a');
      } else {
        out.write(mapped);
      }
    }
    return out.toString();
  }

  /// Lower-case Roman letters and digits; doubled letters and long vowels
  /// folded ("bhallay" → "bhale").
  static String light(String text) {
    var t = roman(text).replaceAll(RegExp('[^a-z0-9]'), '');
    t = t
        .replaceAll('ee', 'i')
        .replaceAll('oo', 'u')
        .replaceAll('aa', 'a');
    t = t.replaceAll(RegExp(r'(ay|ey|ai|ae)$'), 'e');
    return t.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!);
  }

  /// Consonants only, with look-alike sounds merged
  /// ("dahi bhalla" → "dbl", "chicken" → "ckn").
  static String skeleton(String text) {
    var t = roman(text).replaceAll(RegExp('[^a-z0-9]'), '');
    const pairs = [
      ('ch', 'c'), ('sh', 's'), ('kh', 'k'), ('gh', 'g'), ('ph', 'f'),
      ('th', 't'), ('dh', 'd'), ('bh', 'b'), ('jh', 'j'), ('rh', 'r'),
      ('zh', 'z'), ('ck', 'k'),
    ];
    for (final (a, b) in pairs) {
      t = t.replaceAll(a, b);
    }
    t = t.replaceAll('q', 'k').replaceAll('x', 'ks').replaceAll('w', 'v');
    t = t.replaceAll('h', '').replaceAll(RegExp('[aeiouy]'), '');
    return t.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!);
  }

  /// 0–1: how alike two words sound.
  static double wordSim(String a, String b) {
    final la = light(a);
    final lb = light(b);
    if (la.isEmpty || lb.isEmpty) return 0;
    if (la == lb) return 1;
    final s1 = ratio(la, lb);
    final sa = skeleton(a);
    final sb = skeleton(b);
    var s2 = sa.isEmpty || sb.isEmpty ? 0.0 : ratio(sa, sb);
    // One or two consonants say little on their own.
    if (sa.length < 2 || sb.length < 2) s2 = math.min(s2, 0.5 + s1 / 2);
    return math.max(s1, s2);
  }

  /// 0–1 for names of one or more words.
  static double phraseSim(String a, String b) {
    final wa = a.trim().split(RegExp(r'\s+'));
    final wb = b.trim().split(RegExp(r'\s+'));
    if (wa.length == wb.length) {
      var sum = 0.0;
      for (var i = 0; i < wa.length; i++) {
        sum += wordSim(wa[i], wb[i]);
      }
      return sum / wa.length;
    }
    return wordSim(wa.join(), wb.join()) * 0.9;
  }

  /// 1 − edit distance / longer length.
  static double ratio(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    return 1 - _levenshtein(a, b) / math.max(a.length, b.length);
  }

  static int _levenshtein(String a, String b) {
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0);
      cur[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        cur[j] = math.min(
          math.min(cur[j - 1] + 1, prev[j] + 1),
          prev[j - 1] + cost,
        );
      }
      prev = cur;
    }
    return prev[b.length];
  }

  /// "usama saeed" → "Usama Saeed" (Urdu script is kept as said).
  static String displayName(List<String> words) => words
      .map((w) => RegExp('^[a-z]').hasMatch(w)
          ? '${w[0].toUpperCase()}${w.substring(1)}'
          : w)
      .join(' ');
}

// ── Internals ────────────────────────────────────────────────────────────

enum _Kind { word, qty, size, stop, sep }

class _Tok {
  _Tok(this.text, this.kind, {this.qty, this.size});

  final String text;
  final _Kind kind;
  final int? qty;
  final String? size;
}

/// A token and where it was in the sentence.
class _Pos {
  _Pos(this.tok, this.pos);

  final _Tok tok;
  final int pos;
}

class _RawLine {
  int? qty;
  bool afterSep = false;
  final words = <_Pos>[];
  final sizes = <_Pos>[];
  final heard = <String>[];

  bool get isEmpty => qty == null && words.isEmpty && sizes.isEmpty;
}

class _FoundPerson {
  _FoundPerson(this.name, this.start, this.end);

  final String name;

  /// Token range to drop (name and "ke naam pe").
  final int start;
  final int end;
}

class _MenuEntry {
  _MenuEntry(this.product)
      : words = VoiceSaleParser._tokenize(product.name)
            .where((w) => w != ',')
            .toList();

  /// Lowest score that counts as "this item".
  static const minScore = 0.5;

  final ProductModel product;
  final List<String> words;

  /// 0–1: how well [window] names this item.
  double score(List<String> window) {
    if (words.isEmpty || window.isEmpty) return 0;
    var matched = 0.0;
    final used = <int>{};
    for (final w in words) {
      var best = 0.0;
      var bestIdx = -1;
      for (var i = 0; i < window.length; i++) {
        if (used.contains(i)) continue;
        final s = VoiceText.wordSim(window[i], w);
        if (s > best) {
          best = s;
          bestIdx = i;
        }
      }
      if (best >= 0.75) {
        matched += best;
        used.add(bestIdx);
      }
    }
    final coverage = matched / words.length;
    final precision = used.length / window.length;
    final byWords = coverage * (0.7 + 0.3 * precision);
    // Whole name, ignoring where words break ("dahibhalla").
    final a = window.join();
    final b = words.join();
    final joined = VoiceText.skeleton(a).length >= 3 &&
            VoiceText.skeleton(b).length >= 3
        ? VoiceText.wordSim(a, b) * 0.9
        : 0.0;
    return math.max(byWords, joined >= 0.6 ? joined : 0.0);
  }
}

class _Match {
  _Match(this.entry, this.start, this.end, this.score, [this.alternatives = const []]);

  final _MenuEntry entry;

  /// Word range inside the line.
  final int start;
  final int end;
  final double score;
  final List<ProductModel> alternatives;

  _Match shift(int by) =>
      _Match(entry, start + by, end + by, score, alternatives);
}

class _Built {
  _Built({
    required this.heard,
    this.product,
    this.variant,
    this.sizeSaid = false,
    this.qty = 1,
    this.explicitQty = false,
    this.alternatives = const [],
    this.words = const [],
  });

  final String heard;
  final ProductModel? product;
  final ProductVariant? variant;
  final bool sizeSaid;
  final int qty;
  final bool explicitQty;
  final List<ProductModel> alternatives;

  /// Item words of a line that matched nothing.
  final List<String> words;

  _Built copyWith({
    int? qty,
    bool explicit = false,
    ProductVariant? variant,
    bool sizeSaid = false,
  }) =>
      _Built(
        heard: heard,
        product: product,
        variant: variant ?? this.variant,
        sizeSaid: this.sizeSaid || sizeSaid,
        qty: qty ?? this.qty,
        explicitQty: explicitQty || explicit,
        alternatives: alternatives,
        words: words,
      );

  VoiceSaleLine toLine() => VoiceSaleLine(
        heard: product == null && words.isNotEmpty ? words.join(' ') : heard,
        product: product,
        variant: variant,
        qty: qty,
        alternatives: alternatives,
      );
}
