import 'package:pocket_karcha/core/utils/money.dart';

/// Plain calculator maths for the expense calculator.
///
/// Input uses the keypad symbols `+ − × ÷ %` (ASCII `-`, `*`, `/` work too).
/// `×` and `÷` are worked out before `+` and `−`. `%` after a number is that
/// percent; after `+` or `−` it is a percent of everything before it, like a
/// shop calculator: `200+10%` = 220, `200×10%` = 20.
abstract final class CalcEngine {
  static const plus = '+';
  static const minus = '−';
  static const times = '×';
  static const divide = '÷';
  static const percent = '%';

  static const _digits = '0123456789.';

  static String _normalise(String c) => switch (c) {
        '-' => minus,
        '*' || 'x' => times,
        '/' => divide,
        _ => c,
      };

  static bool isOperator(String c) {
    final n = _normalise(c);
    return n == plus || n == minus || n == times || n == divide;
  }

  /// Result of [input], or null when it is empty or can't be worked out
  /// (for example division by zero). A trailing operator is ignored so the
  /// live result keeps showing while the user types.
  static double? evaluate(String input) {
    final tokens = _tokens(input);
    if (tokens == null) return null;
    while (tokens.isNotEmpty &&
        tokens.last is String &&
        tokens.last != percent) {
      tokens.removeLast();
    }
    if (tokens.isEmpty) return null;

    final nums = <double>[];
    final ops = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (t is double) {
        if (nums.length != ops.length) return null;
        var value = t;
        if (i + 1 < tokens.length && tokens[i + 1] == percent) {
          i++;
          if (ops.isNotEmpty && (ops.last == plus || ops.last == minus)) {
            final base = _flat(nums, ops.sublist(0, ops.length - 1));
            if (base == null) return null;
            value = base * t / 100;
          } else {
            value = t / 100;
          }
        }
        nums.add(value);
      } else if (t == percent) {
        return null;
      } else {
        if (nums.length != ops.length + 1) return null;
        ops.add(t as String);
      }
    }
    if (nums.length != ops.length + 1) return null;
    final result = _flat(nums, ops);
    if (result == null || result.isNaN || result.isInfinite) return null;
    return result;
  }

  /// Rounds to paisa so 0.1 + 0.2 shows as 0.3.
  static double roundMoney(double value) => (value * 100).round() / 100;

  static List<Object>? _tokens(String input) {
    final out = <Object>[];
    final number = StringBuffer();
    var valid = true;

    void flush() {
      if (number.isEmpty) return;
      final value = double.tryParse(number.toString());
      if (value == null) valid = false;
      out.add(value ?? 0);
      number.clear();
    }

    for (var i = 0; i < input.length; i++) {
      final c = _normalise(input[i]);
      if (c == ' ' || c == ',') continue;
      if (_digits.contains(c)) {
        number.write(c);
      } else if (c == percent) {
        flush();
        out.add(percent);
      } else if (isOperator(c)) {
        // A minus at the very start is a negative number.
        if (c == minus && out.isEmpty && number.isEmpty) {
          number.write('-');
          continue;
        }
        flush();
        out.add(c);
      } else {
        return null;
      }
    }
    flush();
    return valid ? out : null;
  }

  /// [nums] and [ops] alternate: n0 op0 n1 op1 n2 … (× ÷ first, then + −).
  static double? _flat(List<double> nums, List<String> ops) {
    if (nums.isEmpty) return null;
    final terms = <double>[nums.first];
    final addOps = <String>[];
    for (var i = 0; i < ops.length; i++) {
      final next = nums[i + 1];
      switch (ops[i]) {
        case times:
          terms[terms.length - 1] = terms.last * next;
        case divide:
          if (next == 0) return null;
          terms[terms.length - 1] = terms.last / next;
        default:
          addOps.add(ops[i]);
          terms.add(next);
      }
    }
    var result = terms.first;
    for (var i = 0; i < addOps.length; i++) {
      result = addOps[i] == plus ? result + terms[i + 1] : result - terms[i + 1];
    }
    return result;
  }
}

/// What the user has typed on the keypad, with the usual calculator rules
/// (one dot per number, an operator after an operator replaces it, …).
class CalcInput {
  CalcInput([this.text = '']);

  String text;

  static const clear = 'C';
  static const backspace = '⌫';
  static const doubleZero = '00';
  static const dot = '.';

  bool get isEmpty => text.isEmpty;

  /// Result of the current input, or null.
  double? get result => CalcEngine.evaluate(text);

  /// True when there is something to work out (at least one operator or %).
  bool get hasOperation {
    final body = text.startsWith(CalcEngine.minus) ? text.substring(1) : text;
    return body.split('').any(
          (c) => CalcEngine.isOperator(c) || c == CalcEngine.percent,
        );
  }

  void setValue(double value) {
    text = formatPlainNumber(CalcEngine.roundMoney(value))
        .replaceFirst('-', CalcEngine.minus);
  }

  String get _last => text.isEmpty ? '' : text[text.length - 1];

  /// Digits after the last operator.
  String get _currentNumber {
    var i = text.length;
    while (i > 0 && '0123456789.'.contains(text[i - 1])) {
      i--;
    }
    return text.substring(i);
  }

  void press(String key) {
    switch (key) {
      case clear:
        text = '';
      case backspace:
        if (text.isNotEmpty) text = text.substring(0, text.length - 1);
      case dot:
        if (_last == CalcEngine.percent) return;
        final current = _currentNumber;
        if (current.contains(dot)) return;
        text += current.isEmpty ? '0.' : dot;
      case CalcEngine.percent:
        if (!'0123456789'.contains(_last) || _last.isEmpty) return;
        text += CalcEngine.percent;
      case CalcEngine.plus ||
            CalcEngine.minus ||
            CalcEngine.times ||
            CalcEngine.divide:
        if (text.isEmpty) {
          if (key == CalcEngine.minus) text = CalcEngine.minus;
          return;
        }
        if (CalcEngine.isOperator(_last)) {
          if (text.length == 1) return; // just a leading minus
          text = text.substring(0, text.length - 1) + key;
          return;
        }
        if (_last == dot) text = text.substring(0, text.length - 1);
        text += key;
      case doubleZero:
        final current = _currentNumber;
        if (current.isEmpty || current == '0' || _last == CalcEngine.percent) {
          return;
        }
        text += doubleZero;
      default:
        if (key.length != 1 || !'0123456789'.contains(key)) return;
        if (_last == CalcEngine.percent) return;
        final current = _currentNumber;
        if (current == '0') {
          text = text.substring(0, text.length - 1) + key;
          return;
        }
        if (current.replaceAll(dot, '').length >= 12) return;
        text += key;
    }
  }
}
