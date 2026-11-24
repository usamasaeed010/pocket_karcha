import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/data/models/order_model.dart';
import 'package:pocket_karcha/data/models/person_model.dart';
import 'package:pocket_karcha/data/models/product_model.dart';

/// Which dates a backup file covers. Balances (udhaar, lena-dena) are
/// always "as of now", whatever the period.
enum BackupPeriod {
  thisMonth,
  lastMonth,
  thisYear,
  all;

  /// [from] inclusive, [to] exclusive; nulls = open.
  ({DateTime? from, DateTime? to}) range(DateTime now) => switch (this) {
        thisMonth => (
            from: DateTime(now.year, now.month),
            to: DateTime(now.year, now.month + 1),
          ),
        lastMonth => (
            from: DateTime(now.year, now.month - 1),
            to: DateTime(now.year, now.month),
          ),
        thisYear => (from: DateTime(now.year), to: DateTime(now.year + 1)),
        all => (from: null, to: null),
      };
}

/// Everything one backup file needs, read from the providers at the moment
/// the owner taps Export. Pure data, so the Excel and PDF builders can be
/// tested without Flutter.
class BackupSnapshot {
  BackupSnapshot({
    required this.storeName,
    required this.currency,
    required this.period,
    required this.generatedAt,
    required List<ExpenseModel> entries,
    required this.people,
    required this.ledgers,
    required List<OrderModel> orders,
    required this.menu,
    required this.categoryLabel,
  })  : allEntries = [...entries]..sort((a, b) => b.date.compareTo(a.date)),
        allOrders = [...orders]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final String storeName;

  /// Symbol shown next to amounts, e.g. "Rs".
  final String currency;
  final BackupPeriod period;
  final DateTime generatedAt;

  /// Newest first.
  final List<ExpenseModel> allEntries;
  final List<PersonModel> people;
  final Map<String, PersonLedger> ledgers;

  /// Newest first.
  final List<OrderModel> allOrders;
  final List<ProductModel> menu;

  /// Category id → English name.
  final String Function(String id) categoryLabel;

  late final ({DateTime? from, DateTime? to}) _range =
      period.range(generatedAt);

  DateTime? get from => _range.from;

  /// Last day covered (the range end is exclusive).
  DateTime? get until =>
      _range.to?.subtract(const Duration(days: 1));

  bool _inPeriod(DateTime d) {
    final f = _range.from;
    final t = _range.to;
    return (f == null || !d.isBefore(f)) && (t == null || d.isBefore(t));
  }

  late final List<ExpenseModel> entries =
      allEntries.where((e) => _inPeriod(e.date)).toList();

  late final List<OrderModel> orders =
      allOrders.where((o) => _inPeriod(o.createdAt)).toList();

  late final Map<String, PersonModel> _peopleById = {
    for (final p in people) p.id: p,
  };

  String personName(String? id) =>
      id == null || id.isEmpty ? '' : (_peopleById[id]?.name ?? '');

  // ── Shop totals (in the period) ─────────────────────────────────────────

  late final BackupTotals totals = BackupTotals._(this);

  /// People with money still to settle, biggest first.
  late final List<({PersonModel person, PersonLedger ledger})> balances = [
    for (final p in people)
      if ((ledgers[p.id]?.net ?? 0).abs() >= 0.005)
        (person: p, ledger: ledgers[p.id]!),
  ]..sort((a, b) => b.ledger.net.abs().compareTo(a.ledger.net.abs()));

  // ── Labels shared by Excel and PDF (English, like most account books) ──

  static String bookLabel(EntryBook b) => switch (b) {
        EntryBook.shop => 'Shop',
        EntryBook.personal => 'Personal',
        EntryBook.people => 'Lena-dena',
      };

  static String typeLabel(ExpenseModel e) => switch (e.book) {
        EntryBook.people => e.isIncome ? 'You got' : 'You gave',
        EntryBook.personal => e.isIncome ? 'Money in' : 'Spent',
        EntryBook.shop => switch (e.type) {
            ExpenseRecordType.income => 'Sale',
            ExpenseRecordType.purchase => 'Purchase',
            ExpenseRecordType.expense => 'Expense',
          },
      };

  /// Old entries have no status; they count as paid.
  static String statusLabel(ExpenseModel e) =>
      e.isPending ? 'Pending' : 'Paid';

  static String orderStatusLabel(OrderStatus s) => switch (s) {
        OrderStatus.pending => 'New',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.dispatched => 'Out / ready',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };

  static String paymentLabel(OrderModel o) {
    if (o.isCancelled) return '';
    return switch (o.paymentState) {
      PaymentState.paid => 'Paid',
      PaymentState.partial => 'Part paid',
      PaymentState.unpaid => 'Unpaid',
    };
  }

  static String itemsText(OrderModel o) {
    if (o.isRequest) return o.requestText.trim();
    return o.items
        .map((i) =>
            '${i.qty} × ${i.name}${i.variant.isEmpty ? '' : ' (${i.variant})'}')
        .join(', ');
  }
}

class BackupTotals {
  BackupTotals._(BackupSnapshot s) {
    for (final e in s.entries) {
      switch (e.book) {
        case EntryBook.shop:
          switch (e.type) {
            case ExpenseRecordType.income:
              sales += e.amount;
            case ExpenseRecordType.purchase:
              purchases += e.amount;
            case ExpenseRecordType.expense:
              expenses += e.amount;
          }
        case EntryBook.personal:
          if (!e.isIncome) personalSpent += e.amount;
        case EntryBook.people:
          break;
      }
    }
    // Udhaar is "as of now", so it uses every entry, not just the period.
    for (final e in s.allEntries) {
      if (e.book != EntryBook.shop || !e.isPending) continue;
      if (e.isIncome) {
        toCollect += e.amount;
      } else {
        toPay += e.amount;
      }
    }
    for (final b in s.balances) {
      if (b.ledger.net > 0) {
        peopleToGet += b.ledger.net;
      } else {
        peopleToGive += -b.ledger.net;
      }
    }
    for (final o in s.orders) {
      if (o.isCancelled) continue;
      orderCount++;
      orderValue += o.total;
      orderPaid += o.paid;
      orderDue += o.due;
    }
  }

  double sales = 0;
  double purchases = 0;
  double expenses = 0;
  double personalSpent = 0;
  double toCollect = 0;
  double toPay = 0;
  double peopleToGet = 0;
  double peopleToGive = 0;
  int orderCount = 0;
  double orderValue = 0;
  double orderPaid = 0;
  double orderDue = 0;

  double get profit => sales - purchases - expenses;
}
