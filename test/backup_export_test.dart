import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_karcha/core/utils/backup/backup_excel.dart';
import 'package:pocket_karcha/core/utils/backup/backup_pdf.dart';
import 'package:pocket_karcha/core/utils/backup/backup_snapshot.dart';
import 'package:pocket_karcha/data/models/blocked_customer.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/data/models/order_model.dart';
import 'package:pocket_karcha/data/models/person_model.dart';
import 'package:pocket_karcha/data/models/product_model.dart';

final _now = DateTime(2026, 11, 24, 10);

/// Amounts must be real numbers in Excel; whole ones are read back as ints.
num? _num(CellValue? v) => switch (v) {
      IntCellValue(:final value) => value,
      DoubleCellValue(:final value) => value,
      _ => null,
    };

ExpenseModel _e(
  String id,
  double amount,
  DateTime date, {
  ExpenseRecordType type = ExpenseRecordType.expense,
  EntryBook book = EntryBook.shop,
  EntryStatus? status,
  String? personId,
  String? item,
}) =>
    ExpenseModel(
      id: id,
      amount: amount,
      categoryId: 'cat',
      note: '',
      date: date,
      type: type,
      book: book,
      status: status,
      personId: personId,
      itemName: item,
    );

BackupSnapshot _snap(BackupPeriod period) => BackupSnapshot(
      storeName: 'Usama Burger Point',
      currency: 'Rs',
      period: period,
      generatedAt: _now,
      entries: [
        // This month.
        _e('e1', 150, DateTime(2026, 11, 20),
            type: ExpenseRecordType.income,
            status: EntryStatus.pending,
            personId: 'p1',
            item: 'Dahi Bhalla (Half)'),
        _e('e2', 1000, DateTime(2026, 11, 21),
            type: ExpenseRecordType.income, status: EntryStatus.paid),
        _e('e3', 400, DateTime(2026, 11, 22),
            type: ExpenseRecordType.purchase, status: EntryStatus.paid),
        _e('e4', 250, DateTime(2026, 11, 23),
            book: EntryBook.personal, item: 'دودھ'),
        // Last month: a pending shop bill and money given to a person.
        _e('e5', 300, DateTime(2026, 10, 5),
            type: ExpenseRecordType.purchase, status: EntryStatus.pending),
        _e('e6', 500, DateTime(2026, 10, 10),
            book: EntryBook.people, personId: 'p2'),
      ],
      people: const [
        PersonModel(id: 'p1', name: 'Usama', phoneLocal: '3001234567'),
        PersonModel(id: 'p2', name: 'علی رضا'),
        PersonModel(id: 'p3', name: 'Settled Sb'),
      ],
      ledgers: const {
        'p1': PersonLedger(gave: 150, entries: 1),
        'p2': PersonLedger(gave: 500, got: 700, entries: 2),
        'p3': PersonLedger(gave: 100, got: 100, entries: 2),
      },
      orders: [
        OrderModel(
          id: 'o1',
          number: '123456',
          customer: const OrderCustomer(name: 'Hamza', phone: '03001112223'),
          items: const [
            OrderItem(productId: 'f', name: 'Fries', variant: 'Large', price: 250, qty: 2),
          ],
          subtotal: 500,
          total: 500,
          paid: 200,
          createdAt: DateTime(2026, 11, 22),
        ),
        OrderModel(
          id: 'o2',
          number: '654321',
          status: OrderStatus.cancelled,
          total: 900,
          createdAt: DateTime(2026, 11, 23),
        ),
        OrderModel(
          id: 'o3',
          number: '111111',
          total: 450,
          createdAt: DateTime(2025, 6, 1),
        ),
      ],
      menu: const [
        ProductModel(id: 'd', name: 'Dahi Bhalla', variants: [
          ProductVariant(name: 'Half', price: 150),
          ProductVariant(name: 'Full', price: 250),
        ]),
        ProductModel(id: 's', name: 'Samosa', price: 40, inStock: false),
      ],
      categoryLabel: (id) => 'General',
    );

Future<BackupFonts> _fonts() async {
  Future<ByteData> load(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());
  return BackupFonts(
    regular: await load('assets/fonts/Poppins-Regular.ttf'),
    bold: await load('assets/fonts/Poppins-Bold.ttf'),
    urdu: await load('assets/fonts/NotoNaskhArabic-Regular.ttf'),
  );
}

void main() {
  group('periods and totals', () {
    test('this month only counts this month, udhaar counts everything', () {
      final s = _snap(BackupPeriod.thisMonth);
      expect(s.entries.map((e) => e.id), ['e4', 'e3', 'e2', 'e1']);
      final t = s.totals;
      expect(t.sales, 1150);
      expect(t.purchases, 400);
      expect(t.expenses, 0);
      expect(t.profit, 750);
      expect(t.personalSpent, 250);
      // Pending sale (this month) + pending bill (last month).
      expect(t.toCollect, 150);
      expect(t.toPay, 300);
      expect(t.peopleToGet, 150);
      expect(t.peopleToGive, 200);
      // The cancelled order is left out.
      expect(t.orderCount, 1);
      expect(t.orderValue, 500);
      expect(t.orderPaid, 200);
      expect(t.orderDue, 300);
    });

    test('last month and all time', () {
      expect(_snap(BackupPeriod.lastMonth).entries.map((e) => e.id),
          ['e6', 'e5']);
      final all = _snap(BackupPeriod.all);
      expect(all.entries, hasLength(6));
      expect(all.orders, hasLength(3));
      expect(all.from, isNull);
    });

    test('settled people are not listed as balances', () {
      final names = _snap(BackupPeriod.all).balances.map((b) => b.person.name);
      expect(names, ['علی رضا', 'Usama']);
    });
  });

  test('Excel file has every sheet and real numbers', () {
    final bytes = BackupExcel.build(_snap(BackupPeriod.all));
    final x = Excel.decodeBytes(bytes);
    expect(x.tables.keys,
        containsAll(['Summary', 'Khata', 'People', 'Orders', 'Menu']));
    expect(x.tables.keys, isNot(contains('Sheet1')));

    final khata = x.tables['Khata']!;
    expect(khata.maxRows, 7); // header + 6 entries
    expect(khata.row(0)[1]?.value.toString(), 'Book');
    expect(_num(khata.row(1)[8]?.value), 250);
    expect(khata.row(1)[4]?.value.toString(), 'دودھ');

    final menu = x.tables['Menu']!;
    expect(menu.maxRows, 4); // header + Half + Full + Samosa
    expect(menu.row(3)[4]?.value.toString(), 'No');

    final orders = x.tables['Orders']!;
    // Newest first: the cancelled order (23 Nov), then Hamza's (22 Nov).
    expect(orders.row(1)[3]?.value.toString(), 'Cancelled');
    expect(orders.row(2)[7]?.value.toString(), '2 × Fries (Large)');
    expect(_num(orders.row(2)[12]?.value), 300);
  });

  test('PDF report builds with Urdu names', () async {
    final pdf = await BackupPdf.build(
      _snap(BackupPeriod.all),
      fonts: await _fonts(),
      money: (n) => 'Rs ${n.toStringAsFixed(0)}',
    );
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    expect(pdf.length, greaterThan(5000));
  });

  test('a long khata spreads over several PDF pages', () async {
    final many = BackupSnapshot(
      storeName: 'Big Shop',
      currency: 'Rs',
      period: BackupPeriod.all,
      generatedAt: _now,
      entries: [
        for (var i = 0; i < 400; i++)
          _e('x$i', 10.0 + i, DateTime(2026, 1, 1).add(Duration(hours: i)),
              type: ExpenseRecordType.income, status: EntryStatus.paid),
      ],
      people: const [],
      ledgers: const {},
      orders: const [],
      menu: const [],
      categoryLabel: (_) => 'Sale',
    );
    final pdf = await BackupPdf.build(many,
        fonts: await _fonts(), money: (n) => 'Rs $n');
    final pages = RegExp(r'/Type\s*/Page[^s]')
        .allMatches(String.fromCharCodes(pdf))
        .length;
    expect(pages, greaterThan(3));
  });

  group('blocking keys', () {
    test('every common way of writing a Pakistani number', () {
      final keys = BlockedCustomer.keysFor(
        phone: '0300-1234567',
        buyerUid: 'abcUID',
      );
      expect(
        keys,
        containsAll([
          '03001234567',
          '3001234567',
          '923001234567',
          '00923001234567',
          'abcUID',
        ]),
      );
    });

    test('national number from any form', () {
      for (final p in ['03001234567', '923001234567', '+92 300 1234567', '00923001234567']) {
        expect(BlockedCustomer.nationalNumber(p), '3001234567', reason: p);
      }
      expect(BlockedCustomer.groupFor(phone: '', buyerUid: 'u1'), 'u1');
    });

    test('blocks group into one customer, newest first', () {
      final list = BlockedCustomer.fromEntries([
        BlockedEntry(key: '0300', group: 'g1', name: 'Old', createdAt: DateTime(2026, 1, 1)),
        BlockedEntry(key: '92300', group: 'g1', phone: '0300', createdAt: DateTime(2026, 1, 1)),
        BlockedEntry(key: 'u9', group: 'g2', name: 'New', createdAt: DateTime(2026, 5, 1)),
      ]);
      expect(list.map((c) => c.group), ['g2', 'g1']);
      expect(list[1].keys, ['0300', '92300']);
      expect(list[1].phone, '0300');
    });
  });
}
