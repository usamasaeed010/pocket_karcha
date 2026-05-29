import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseRecordType { expense, income }

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
  });

  final String id;
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;
  final DateTime? createdAt;
  final String? receiptUrl;
  /// [ExpenseRecordType.expense] = You Gave, [ExpenseRecordType.income] = You Got.
  final ExpenseRecordType type;
  final String? personId;

  bool get hasReceipt => receiptUrl != null && receiptUrl!.isNotEmpty;
  bool get isIncome => type == ExpenseRecordType.income;

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
    );
  }

  static ExpenseRecordType _parseType(dynamic value) {
    if (value == ExpenseRecordType.income.name) {
      return ExpenseRecordType.income;
    }
    return ExpenseRecordType.expense;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
