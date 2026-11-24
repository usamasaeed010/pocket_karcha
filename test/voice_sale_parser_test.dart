import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/data/models/person_model.dart';
import 'package:pocket_karcha/data/models/product_model.dart';
import 'package:pocket_karcha/features/voice/voice_sale_parser.dart';

ProductModel _item(String id, String name,
        {double price = 0, Map<String, double> sizes = const {}}) =>
    ProductModel(
      id: id,
      name: name,
      price: price,
      variants: [
        for (final e in sizes.entries) ProductVariant(name: e.key, price: e.value),
      ],
    );

final _menu = [
  _item('dahi', 'Dahi Bhalla', sizes: {'Half': 150, 'Full': 250}),
  _item('samosa', 'Samosa', price: 40),
  _item('biryani', 'Chicken Biryani', sizes: {'Half': 200, 'Full': 350}),
  _item('karahi', 'Chicken Karahi', sizes: {'Half': 900, 'Full': 1700}),
  _item('chai', 'Chai', price: 60),
  _item('zinger', 'Zinger Burger', price: 450),
  _item('fries', 'Fries', sizes: {'Small': 150, 'Large': 250}),
  _item('lassi', 'Lassi', sizes: {'Meethi': 150, 'Namkeen': 160}),
];

const _usama = PersonModel(id: 'p1', name: 'Usama');
const _ali = PersonModel(id: 'p2', name: 'Ali Raza');
const _people = [_usama, _ali];

VoiceSaleDraft _parse(String text) =>
    VoiceSaleParser.parse(text, menu: _menu, people: _people);

void main() {
  test('Roman: 1 dahi bhalla half on Usama’s name', () {
    final d = _parse('1 dahi bhalla half add kr do usama k name pe');
    expect(d.lines, hasLength(1));
    final l = d.lines.single;
    expect(l.product?.id, 'dahi');
    expect(l.variant?.name, 'Half');
    expect(l.qty, 1);
    expect(l.total, 150);
    expect(l.label, 'Dahi Bhalla (Half)');
    expect(d.personName, 'Usama');
    expect(d.person?.id, 'p1');
    expect(d.status, isNull);
  });

  test('Urdu script is read the same way', () {
    final d = _parse('ایک دہی بھلے ہاف اسامہ کے نام پے لکھ دو');
    expect(d.lines.single.product?.id, 'dahi');
    expect(d.lines.single.variant?.name, 'Half');
    expect(d.lines.single.qty, 1);
    expect(d.person?.id, 'p1');
  });

  test('several items, ledger words and a first name', () {
    final d = _parse('2 samose aur 1 chicken biryani full ali ke khate mein');
    expect(d.lines, hasLength(2));
    expect(d.lines[0].product?.id, 'samosa');
    expect(d.lines[0].qty, 2);
    expect(d.lines[0].total, 80);
    expect(d.lines[1].product?.id, 'biryani');
    expect(d.lines[1].variant?.name, 'Full');
    expect(d.total, 430);
    expect(d.person?.id, 'p2');
  });

  test('number words and no name', () {
    final d = _parse('teen chai');
    expect(d.lines.single.product?.id, 'chai');
    expect(d.lines.single.qty, 3);
    expect(d.personName, isNull);
  });

  test('size not said → needs a size', () {
    final d = _parse('dahi bhalla usama ke naam');
    expect(d.lines.single.product?.id, 'dahi');
    expect(d.lines.single.needsSize, isTrue);
    expect(d.lines.single.isReady, isFalse);
    expect(d.person?.id, 'p1');
  });

  test('"kar do" is not two, "do samose" is', () {
    expect(_parse('samosa add kar do').lines.single.qty, 1);
    expect(_parse('do samose').lines.single.qty, 2);
  });

  test('new person and udhaar', () {
    final d = _parse('1 zinger burger hamza ke naam pe udhaar');
    expect(d.lines.single.product?.id, 'zinger');
    expect(d.personName, 'Hamza');
    expect(d.person, isNull);
    expect(d.status, EntryStatus.pending);
  });

  test('cash means paid; size word picks the size', () {
    final d = _parse('2 fries large cash');
    expect(d.lines.single.variant?.name, 'Large');
    expect(d.lines.single.total, 500);
    expect(d.status, EntryStatus.paid);
  });

  test('size by its own name (not half/full)', () {
    final d = _parse('1 lassi namkeen');
    expect(d.lines.single.variant?.name, 'Namkeen');
  });

  test('item not on the menu stays as heard', () {
    final d = _parse('2 pakore usama ke naam');
    expect(d.lines.single.isMatched, isFalse);
    expect(d.lines.single.heard, 'pakore');
    expect(d.lines.single.qty, 2);
    expect(d.person?.id, 'p1');
  });

  test('same item in two sizes', () {
    final d = _parse('dahi bhalla 1 half aur 2 full');
    expect(d.lines, hasLength(2));
    expect(d.lines[0].variant?.name, 'Half');
    expect(d.lines[0].qty, 1);
    expect(d.lines[1].product?.id, 'dahi');
    expect(d.lines[1].variant?.name, 'Full');
    expect(d.lines[1].qty, 2);
    expect(d.total, 650);
  });

  test('a spoken price is not a count', () {
    final d = _parse('1 samosa 40 rupay');
    expect(d.lines.single.product?.id, 'samosa');
    expect(d.lines.single.qty, 1);
  });

  test('spelling and speech mistakes', () {
    final d = _parse('dahee bhallay haaf');
    expect(d.lines.single.product?.id, 'dahi');
    expect(d.lines.single.variant?.name, 'Half');
  });

  test('half a name → other close items are offered', () {
    final d = _parse('chicken half');
    final l = d.lines.single;
    expect(l.product?.id, anyOf('biryani', 'karahi'));
    expect(l.alternatives.map((p) => p.id), contains(anyOf('biryani', 'karahi')));
    expect(l.variant?.name, 'Half');
  });

  test('known person said without "ke naam"', () {
    final d = _parse('usama 2 samose');
    expect(d.person?.id, 'p1');
    expect(d.lines.single.product?.id, 'samosa');
    expect(d.lines.single.qty, 2);
  });

  test('"bhai" and an item after the name', () {
    final d = _parse('usama bhai ke naam 1 chai');
    expect(d.person?.id, 'p1');
    expect(d.lines.single.product?.id, 'chai');
  });

  test('a word right after a count is the item, not the name', () {
    final d = _parse('1 pakora ali ke naam');
    expect(d.personName, 'Ali');
    expect(d.person?.id, 'p2');
    expect(d.lines.single.heard, 'pakora');
  });

  test('picks the best of the speech guesses', () {
    final r = VoiceSaleParser.parseBest(
      ['the weather is nice', 'dahi bhalla half'],
      menu: _menu,
      people: _people,
    );
    expect(r.text, 'dahi bhalla half');
    expect(r.draft.lines.single.product?.id, 'dahi');
  });

  test('loose matching basics', () {
    expect(VoiceText.skeleton('dahi bhalla'), 'dbl');
    expect(VoiceText.skeleton('دہی بھلا'), 'dbl');
    expect(VoiceText.wordSim('samose', 'samosa'), greaterThan(0.9));
    expect(VoiceText.wordSim('usama', 'samosa'), lessThan(0.75));
    expect(VoiceText.wordSim('chai', 'chana'), lessThan(0.75));
  });
}
