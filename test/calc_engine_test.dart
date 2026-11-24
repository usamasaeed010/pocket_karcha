import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_karcha/features/calculator/calc_engine.dart';

void main() {
  group('CalcEngine.evaluate', () {
    test('adds a bill', () {
      expect(CalcEngine.evaluate('250+120+80'), 450);
    });

    test('× and ÷ before + and −', () {
      expect(CalcEngine.evaluate('100+2×50'), 200);
      expect(CalcEngine.evaluate('100−30÷3'), 90);
    });

    test('percent of the amount before + or −', () {
      expect(CalcEngine.evaluate('200+10%'), 220);
      expect(CalcEngine.evaluate('1000−5%'), 950);
    });

    test('percent after × is a plain percent', () {
      expect(CalcEngine.evaluate('200×10%'), 20);
      expect(CalcEngine.evaluate('50%'), 0.5);
    });

    test('ignores a trailing operator', () {
      expect(CalcEngine.evaluate('250+'), 250);
    });

    test('negative start and ASCII operators', () {
      expect(CalcEngine.evaluate('-50+20'), -30);
      expect(CalcEngine.evaluate('6*7'), 42);
    });

    test('bad input gives null', () {
      expect(CalcEngine.evaluate(''), isNull);
      expect(CalcEngine.evaluate('5÷0'), isNull);
      expect(CalcEngine.evaluate('1.2.3+1'), isNull);
      expect(CalcEngine.evaluate('%'), isNull);
    });

    test('rounds to paisa', () {
      expect(CalcEngine.roundMoney(CalcEngine.evaluate('0.1+0.2')!), 0.3);
    });
  });

  group('CalcInput', () {
    CalcInput type(String keys) {
      final input = CalcInput();
      for (final k in keys.split(' ')) {
        input.press(k);
      }
      return input;
    }

    test('operator after operator replaces it', () {
      expect(type('5 + −').text, '5−');
    });

    test('one dot per number', () {
      expect(type('1 . 5 . 2').text, '1.52');
      expect(type('. 5').text, '0.5');
    });

    test('leading zero is replaced', () {
      expect(type('0 7').text, '7');
      expect(type('0 00').text, '0');
    });

    test('backspace and clear', () {
      expect(type('1 2 3 ⌫').text, '12');
      expect(type('1 2 C').text, '');
    });

    test('percent only after a digit', () {
      expect(type('% 5').text, '5');
      expect(type('2 0 0 + 1 0 %').result, 220);
    });

    test('hasOperation', () {
      expect(type('2 5').hasOperation, isFalse);
      expect(type('− 2 5').hasOperation, isFalse);
      expect(type('2 + 5').hasOperation, isTrue);
    });
  });
}
