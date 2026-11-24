import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pocket_karcha/core/utils/backup/backup_snapshot.dart';

/// Font files for the PDF. Poppins has no Urdu letters, so Noto Naskh
/// Arabic is the fallback for names and notes written in Urdu.
class BackupFonts {
  const BackupFonts({
    required this.regular,
    required this.bold,
    required this.urdu,
  });

  final ByteData regular;
  final ByteData bold;
  final ByteData urdu;
}

/// A printable report: totals, lena-dena balances, khata entries and orders
/// for the chosen period.
abstract final class BackupPdf {
  static final _date = DateFormat('d MMM yyyy');
  static final _arabic =
      RegExp(r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]');

  static const _brand = PdfColor.fromInt(0xFF13784B);
  static const _brandSoft = PdfColor.fromInt(0xFFDFF3E7);
  static const _ink = PdfColor.fromInt(0xFF1F2A24);
  static const _soft = PdfColor.fromInt(0xFF5F6B64);
  static const _line = PdfColor.fromInt(0xFFDDE3DF);
  static const _zebra = PdfColor.fromInt(0xFFF6F8F7);
  static const _red = PdfColor.fromInt(0xFFB42318);

  static Future<Uint8List> build(
    BackupSnapshot s, {
    required BackupFonts fonts,
    required String Function(num) money,
  }) {
    final urdu = pw.Font.ttf(fonts.urdu);
    final theme = pw.ThemeData.withFont(
      base: pw.Font.ttf(fonts.regular),
      bold: pw.Font.ttf(fonts.bold),
      fontFallback: [urdu],
    );
    final title = s.storeName.isEmpty ? 'Pocket Karcha' : s.storeName;
    final doc = pw.Document(
      title: '$title report',
      author: 'Pocket Karcha',
      theme: theme,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 24),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Pocket Karcha · page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _soft),
          ),
        ),
        build: (ctx) => [
          _header(s, title),
          pw.SizedBox(height: 14),
          _summary(s, money),
          ..._section(
            'Lena-dena balances (as of now)',
            s.balances.isEmpty
                ? null
                : _table(
                    headers: ['Name', 'Phone', 'Balance', 'Who pays'],
                    widths: const [3, 2.4, 1.8, 2],
                    rightAligned: const {2},
                    rows: [
                      for (final b in s.balances)
                        [
                          b.person.name,
                          b.person.phoneLocal.isEmpty
                              ? ''
                              : b.person.displayPhone,
                          money(b.ledger.net.abs()),
                          b.ledger.net > 0 ? 'They pay you' : 'You pay them',
                        ],
                    ],
                  ),
            empty: 'Everyone is settled.',
          ),
          ..._section(
            'Khata entries',
            s.entries.isEmpty
                ? null
                : _table(
                    headers: [
                      'Date', 'Book', 'Type', 'Item / category', 'Person',
                      'Status', 'Amount',
                    ],
                    widths: const [1.6, 1.3, 1.3, 3, 2, 1.3, 1.8],
                    rightAligned: const {6},
                    redWhen: (r) => r[5] == 'Pending',
                    rows: [
                      for (final e in s.entries)
                        [
                          _date.format(e.date),
                          BackupSnapshot.bookLabel(e.book),
                          BackupSnapshot.typeLabel(e),
                          _itemText(
                            e.itemName,
                            s.categoryLabel(e.categoryId),
                            e.note,
                          ),
                          s.personName(e.personId),
                          BackupSnapshot.statusLabel(e),
                          money(e.amount),
                        ],
                    ],
                  ),
            empty: 'No khata entries in this period.',
          ),
          ..._section(
            'Orders',
            s.orders.isEmpty
                ? null
                : _table(
                    headers: [
                      'Date', '#', 'Customer', 'Items', 'Total', 'Due',
                      'Status',
                    ],
                    widths: const [1.6, 1.1, 2.2, 3.6, 1.6, 1.5, 1.6],
                    rightAligned: const {4, 5},
                    rows: [
                      for (final o in s.orders)
                        [
                          _date.format(o.createdAt),
                          o.number,
                          o.displayName,
                          BackupSnapshot.itemsText(o),
                          money(o.total),
                          o.isCancelled ? '' : money(o.due),
                          BackupSnapshot.orderStatusLabel(o.status),
                        ],
                    ],
                  ),
            empty: 'No orders in this period.',
          ),
        ],
      ),
    );
    return doc.save();
  }

  // ── pieces ───────────────────────────────────────────────────────────────

  static String _periodText(BackupSnapshot s) {
    final f = s.from;
    final u = s.until;
    if (f == null || u == null) return 'All time';
    return '${_date.format(f)} – ${_date.format(u)}';
  }

  static String _itemText(String? item, String category, String note) {
    final main = (item ?? '').trim().isNotEmpty ? item!.trim() : category;
    final n = note.trim();
    return n.isEmpty || n == main ? main : '$main — $n';
  }

  /// Urdu (Arabic-script) text must be laid out right to left to be shaped.
  static pw.Widget _text(String value, pw.TextStyle style,
      {bool right = false}) {
    final rtl = _arabic.hasMatch(value);
    return pw.Text(
      value,
      style: style,
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      textAlign: right || rtl ? pw.TextAlign.right : pw.TextAlign.left,
    );
  }

  static pw.Widget _header(BackupSnapshot s, String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _brandSoft,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _text(
                  title,
                  pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Khata & orders report · ${_periodText(s)}',
                  style: const pw.TextStyle(fontSize: 10, color: _soft),
                ),
              ],
            ),
          ),
          pw.Text(
            'Made ${DateFormat('d MMM yyyy, h:mm a').format(s.generatedAt)}',
            style: const pw.TextStyle(fontSize: 8, color: _soft),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summary(BackupSnapshot s, String Function(num) money) {
    final t = s.totals;
    pw.Widget box(String label, num value, {bool strong = false}) {
      return pw.Container(
        width: 170,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _soft)),
            pw.SizedBox(height: 2),
            pw.Text(
              money(value),
              style: pw.TextStyle(
                fontSize: strong ? 13 : 11.5,
                fontWeight: pw.FontWeight.bold,
                color: value < 0 ? _red : (strong ? _brand : _ink),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        box('Sales', t.sales),
        box('Purchases', t.purchases),
        box('Expenses', t.expenses),
        box('Profit', t.profit, strong: true),
        box('Shop udhaar to collect (now)', t.toCollect),
        box('Shop bills to pay (now)', t.toPay),
        box("Lena-dena: you'll get (now)", t.peopleToGet),
        box("Lena-dena: you'll give (now)", t.peopleToGive),
        box('Personal spending', t.personalSpent),
        box('Orders: ${t.orderCount} worth', t.orderValue),
        box('Orders: received', t.orderPaid),
        box('Orders: still due', t.orderDue),
      ],
    );
  }

  static List<pw.Widget> _section(
    String title,
    pw.Widget? body, {
    required String empty,
  }) {
    return [
      pw.SizedBox(height: 18),
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: _brand,
        ),
      ),
      pw.SizedBox(height: 6),
      body ??
          pw.Text(empty, style: const pw.TextStyle(fontSize: 9, color: _soft)),
    ];
  }

  static pw.Widget _table({
    required List<String> headers,
    required List<double> widths,
    required List<List<String>> rows,
    Set<int> rightAligned = const {},
    bool Function(List<String> row)? redWhen,
  }) {
    const cell = pw.TextStyle(fontSize: 8, color: _ink);
    const cellRed = pw.TextStyle(fontSize: 8, color: _red);
    return pw.TableHelper.fromTextArray(
      headers: headers,
      columnWidths: {
        for (var i = 0; i < widths.length; i++)
          i: pw.FlexColumnWidth(widths[i]),
      },
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: _brand,
      ),
      headerDecoration: const pw.BoxDecoration(color: _brandSoft),
      oddRowDecoration: const pw.BoxDecoration(color: _zebra),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      border: null,
      headerAlignments: {
        for (final i in rightAligned) i: pw.Alignment.centerRight,
      },
      cellAlignments: {
        for (final i in rightAligned) i: pw.Alignment.centerRight,
      },
      data: [
        for (final r in rows)
          [
            for (var i = 0; i < r.length; i++)
              _text(
                r[i],
                (redWhen?.call(r) ?? false) && i == r.length - 1
                    ? cellRed
                    : cell,
                right: rightAligned.contains(i),
              ),
          ],
      ],
    );
  }
}
