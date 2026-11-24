import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pocket_karcha/core/utils/backup/backup_snapshot.dart';
import 'package:pocket_karcha/data/models/order_model.dart';

/// The full backup as one Excel file: Summary, Khata, People, Orders, Menu.
/// Amounts are real numbers, so the owner (or an accountant) can add them
/// up in Excel / Google Sheets.
abstract final class BackupExcel {
  static final _date = DateFormat('d MMM yyyy');

  static List<int> build(BackupSnapshot s) {
    final x = Excel.createExcel();
    final first = x.getDefaultSheet() ?? 'Sheet1';
    x.rename(first, 'Summary');
    _summary(x['Summary'], s);
    _khata(x['Khata'], s);
    _people(x['People'], s);
    _orders(x['Orders'], s);
    _menu(x['Menu'], s);
    x.setDefaultSheet('Summary');
    final bytes = x.encode();
    if (bytes == null) throw StateError('Excel file could not be written');
    return bytes;
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  static final _head = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#DFF3E7'),
    fontColorHex: ExcelColor.fromHexString('#0F5132'),
  );
  static final _bold = CellStyle(bold: true);

  static CellValue? _v(Object? value) => switch (value) {
        null => null,
        final String s => s.isEmpty ? null : TextCellValue(s),
        final int i => IntCellValue(i),
        final double d => DoubleCellValue(_round(d)),
        final DateTime d => DateCellValue.fromDateTime(d),
        _ => TextCellValue(value.toString()),
      };

  static double _round(double d) => (d * 100).roundToDouble() / 100;

  static void _row(Sheet sheet, List<Object?> cells, {CellStyle? style}) {
    sheet.appendRow([for (final c in cells) _v(c)]);
    if (style == null) return;
    final r = sheet.maxRows - 1;
    for (var c = 0; c < cells.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
          .cellStyle = style;
    }
  }

  static void _widths(Sheet sheet, List<double> widths) {
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  static String _periodText(BackupSnapshot s) {
    final f = s.from;
    final u = s.until;
    if (f == null || u == null) return 'All time';
    return '${_date.format(f)} – ${_date.format(u)}';
  }

  // ── sheets ───────────────────────────────────────────────────────────────

  static void _summary(Sheet sh, BackupSnapshot s) {
    final t = s.totals;
    final c = s.currency;
    _widths(sh, [34, 18]);
    _row(sh, [s.storeName.isEmpty ? 'Pocket Karcha' : s.storeName], style: _bold);
    _row(sh, ['Backup made', DateFormat('d MMM yyyy, h:mm a').format(s.generatedAt)]);
    _row(sh, ['Period', _periodText(s)]);
    _row(sh, []);
    _row(sh, ['Shop (period)', 'Amount ($c)'], style: _head);
    _row(sh, ['Sales', t.sales]);
    _row(sh, ['Purchases', t.purchases]);
    _row(sh, ['Expenses', t.expenses]);
    _row(sh, ['Profit', t.profit], style: _bold);
    _row(sh, []);
    _row(sh, ['Udhaar (as of now)', 'Amount ($c)'], style: _head);
    _row(sh, ['Shop: to collect', t.toCollect]);
    _row(sh, ['Shop: to pay', t.toPay]);
    _row(sh, ['Lena-dena: you will get', t.peopleToGet]);
    _row(sh, ['Lena-dena: you will give', t.peopleToGive]);
    _row(sh, []);
    _row(sh, ['Personal (period)', 'Amount ($c)'], style: _head);
    _row(sh, ['Spent', t.personalSpent]);
    _row(sh, []);
    _row(sh, ['Link orders (period)', 'Amount ($c)'], style: _head);
    _row(sh, ['Orders (not cancelled)', t.orderCount]);
    _row(sh, ['Order value', t.orderValue]);
    _row(sh, ['Received', t.orderPaid]);
    _row(sh, ['Still due', t.orderDue]);
  }

  static void _khata(Sheet sh, BackupSnapshot s) {
    _widths(sh, [13, 11, 11, 16, 24, 7, 9, 11, 13, 10, 18, 30]);
    _row(
      sh,
      [
        'Date', 'Book', 'Type', 'Category', 'Item', 'Qty', 'Unit',
        'Rate (${s.currency})', 'Amount (${s.currency})', 'Status', 'Person',
        'Note',
      ],
      style: _head,
    );
    for (final e in s.entries) {
      _row(sh, [
        e.date,
        BackupSnapshot.bookLabel(e.book),
        BackupSnapshot.typeLabel(e),
        s.categoryLabel(e.categoryId),
        e.itemName ?? '',
        e.quantity,
        e.unit ?? '',
        e.unitPrice,
        e.amount,
        BackupSnapshot.statusLabel(e),
        s.personName(e.personId),
        e.note,
      ]);
    }
  }

  static void _people(Sheet sh, BackupSnapshot s) {
    _widths(sh, [22, 17, 14, 14, 14, 16, 9, 14]);
    _row(
      sh,
      [
        'Name', 'Phone', 'You gave (${s.currency})', 'You got (${s.currency})',
        'Balance (${s.currency})', 'Who pays', 'Entries', 'Last entry',
      ],
      style: _head,
    );
    for (final p in s.people) {
      final l = s.ledgers[p.id];
      final net = l?.net ?? 0;
      _row(sh, [
        p.name,
        p.phoneLocal.isEmpty ? '' : p.displayPhone,
        l?.gave ?? 0.0,
        l?.got ?? 0.0,
        net.abs(),
        net > 0.004
            ? 'They pay you'
            : net < -0.004
                ? 'You pay them'
                : 'Settled',
        l?.entries ?? 0,
        l?.lastActivity,
      ]);
    }
  }

  static void _orders(Sheet sh, BackupSnapshot s) {
    _widths(sh, [13, 9, 9, 12, 20, 15, 26, 40, 11, 11, 11, 11, 11, 11, 24]);
    final c = s.currency;
    _row(
      sh,
      [
        'Date', 'Order #', 'From', 'Status', 'Customer', 'Phone', 'Address',
        'Items', 'Subtotal ($c)', 'Delivery ($c)', 'Total ($c)', 'Paid ($c)',
        'Due ($c)', 'Payment', 'Note',
      ],
      style: _head,
    );
    for (final o in s.orders) {
      _row(sh, [
        o.createdAt,
        o.number,
        o.source == OrderSource.link ? 'Link' : 'Counter',
        BackupSnapshot.orderStatusLabel(o.status),
        o.customer.name,
        o.customer.phone,
        o.customer.address,
        BackupSnapshot.itemsText(o),
        o.subtotal,
        o.deliveryFee,
        o.total,
        o.paid,
        o.due,
        BackupSnapshot.paymentLabel(o),
        o.note,
      ]);
    }
  }

  static void _menu(Sheet sh, BackupSnapshot s) {
    _widths(sh, [26, 16, 12, 12, 10]);
    _row(sh, ['Item', 'Category', 'Size', 'Price (${s.currency})', 'In stock'],
        style: _head);
    for (final p in s.menu) {
      final stock = p.inStock ? 'Yes' : 'No';
      if (p.variants.isEmpty) {
        _row(sh, [p.name, p.category, '', p.price, stock]);
      } else {
        for (final v in p.variants) {
          _row(sh, [p.name, p.category, v.name, v.price, stock]);
        }
      }
    }
  }
}
