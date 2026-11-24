import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored `type` of a transaction (Firestore field `type`).
///
/// * [income] — **Sale** / money in (cash sale, orders, other income).
/// * [expense] — **Expense** / running cost (rent, bills, salary, gas…).
/// * [purchase] — **Purchase** / stock or raw material bought for the shop
///   (bulk fruit, buns, milk, packing…). Counts as money out.
enum ExpenseRecordType { expense, income, purchase }

/// Which khata an entry belongs to (Firestore field `book`; missing = shop).
///
/// * [shop] — the shop's sales, purchases and expenses.
/// * [personal] — the owner's own / home spending. Never counted in the shop.
/// * [people] — lena-dena with one person ([ExpenseModel.personId]):
///   `expense` = you gave, `income` = you got. Not counted anywhere else.
enum EntryBook { shop, personal, people }

/// Whether the money of an entry has changed hands yet (Firestore field
/// `status`).
///
/// * [paid] — settled when it was written.
/// * [pending] — udhaar: a sale the customer still has to pay, or a
///   purchase / expense / bill you still have to pay.
///
/// Older entries have no status (null) and count as paid.
enum EntryStatus { paid, pending }

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.note,
    required this.date,
    this.createdAt,
    this.receiptUrl,
    this.type = ExpenseRecordType.expense,
    this.personId,
    this.itemName,
    this.quantity,
    this.unit,
    this.unitPrice,
    this.book = EntryBook.shop,
    this.status,
  });

  final String id;

  /// Total amount of the entry (quantity × rate when item details are given).
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;
  final DateTime? createdAt;

  /// Receipt image URL.
  ///
  /// Image attachments are disabled for now — the field is only kept so that
  /// older records keep their data when they are edited.
  final String? receiptUrl;
  final ExpenseRecordType type;
  final String? personId;

  /// Item bought or sold, e.g. "Bananas" or "Zinger burger".
  final String? itemName;

  /// Quantity in [unit], e.g. `12`.
  final double? quantity;

  /// Unit key from `StockUnits`, e.g. `dozen`, `kg`, `piece`.
  final String? unit;

  /// Rate per [unit].
  final double? unitPrice;

  /// Shop, personal or lena-dena — see [EntryBook].
  final EntryBook book;

  /// Paid or pending — see [EntryStatus]. Null on older entries.
  final EntryStatus? status;

  /// Money still to collect (sale) or to pay (purchase, expense, bill).
  bool get isPending => status == EntryStatus.pending;

  // Image attachments are hidden for now — not used anywhere in the UI.
  // bool get hasReceipt => receiptUrl != null && receiptUrl!.isNotEmpty;

  bool get isIncome => type == ExpenseRecordType.income;
  bool get isPurchase => type == ExpenseRecordType.purchase;
  bool get isExpense => type == ExpenseRecordType.expense;

  /// Purchases and expenses are both money going out of the shop.
  bool get isOutflow => !isIncome;

  bool get hasItemName => itemName != null && itemName!.trim().isNotEmpty;
  bool get hasQuantity => quantity != null && quantity! > 0;

  ExpenseModel copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    String? receiptUrl,
    ExpenseRecordType? type,
    String? personId,
    bool clearPersonId = false,
    String? itemName,
    double? quantity,
    String? unit,
    double? unitPrice,
    bool clearItemDetails = false,
    EntryBook? book,
    EntryStatus? status,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      type: type ?? this.type,
      personId: clearPersonId ? null : (personId ?? this.personId),
      itemName: clearItemDetails ? null : (itemName ?? this.itemName),
      quantity: clearItemDetails ? null : (quantity ?? this.quantity),
      unit: clearItemDetails ? null : (unit ?? this.unit),
      unitPrice: clearItemDetails ? null : (unitPrice ?? this.unitPrice),
      book: book ?? this.book,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'categoryId': categoryId,
        'note': note,
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
        'type': type.name,
        if (receiptUrl != null) 'receiptUrl': receiptUrl,
        if (personId != null) 'personId': personId,
        if (hasItemName) 'itemName': itemName!.trim(),
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (unitPrice != null) 'unitPrice': unitPrice,
        // Shop entries keep their old shape (no field = shop).
        if (book != EntryBook.shop) 'book': book.name,
        if (status != null) 'status': status!.name,
      };

  factory ExpenseModel.fromMap(String id, Map<String, dynamic> map) {
    return ExpenseModel(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as String? ?? 'other',
      note: map['note'] as String? ?? '',
      date: _parseDate(map['date']),
      createdAt: map['createdAt'] != null ? _parseDate(map['createdAt']) : null,
      receiptUrl: map['receiptUrl'] as String?,
      type: _parseType(map['type']),
      personId: map['personId'] as String?,
      itemName: map['itemName'] as String?,
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      unitPrice: (map['unitPrice'] as num?)?.toDouble(),
      book: _parseBook(map['book']),
      status: _parseStatus(map['status']),
    );
  }

  static EntryStatus? _parseStatus(dynamic value) {
    for (final st in EntryStatus.values) {
      if (st.name == value) return st;
    }
    return null;
  }

  static EntryBook _parseBook(dynamic value) {
    for (final b in EntryBook.values) {
      if (b.name == value) return b;
    }
    return EntryBook.shop;
  }

  static ExpenseRecordType _parseType(dynamic value) {
    for (final t in ExpenseRecordType.values) {
      if (t.name == value) return t;
    }
    return ExpenseRecordType.expense;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
