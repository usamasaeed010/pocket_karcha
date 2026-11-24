import 'package:pocket_karcha/data/models/category_model.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';

/// The three kinds of shop entries.
///
/// * [got] — **Sale** / money in (cash sale, orders, other income).
/// * [purchase] — **Purchase** / stock & raw material bought in bulk
///   (fruit, buns, milk, packing…). Money out.
/// * [gave] — **Expense** / running cost (rent, bills, salary, gas…).
///   Money out.
///
/// The `got` / `gave` names are kept from the original "You Got / You Gave"
/// design so older code and saved preferences keep working.
enum TransactionType {
  got,
  purchase,
  gave;

  bool get isIncome => this == TransactionType.got;
  bool get isPurchase => this == TransactionType.purchase;
  bool get isExpense => this == TransactionType.gave;

  /// Sales and purchases always show item / quantity / rate fields;
  /// expenses show them on demand.
  bool get showsItemsByDefault => this != TransactionType.gave;

  ExpenseRecordType get recordType => switch (this) {
        TransactionType.got => ExpenseRecordType.income,
        TransactionType.purchase => ExpenseRecordType.purchase,
        TransactionType.gave => ExpenseRecordType.expense,
      };

  CategoryScope get categoryScope => switch (this) {
        TransactionType.got => CategoryScope.got,
        TransactionType.purchase => CategoryScope.stock,
        TransactionType.gave => CategoryScope.gave,
      };

  static TransactionType fromRecord(ExpenseRecordType type) => switch (type) {
        ExpenseRecordType.income => TransactionType.got,
        ExpenseRecordType.purchase => TransactionType.purchase,
        ExpenseRecordType.expense => TransactionType.gave,
      };

  static TransactionType fromScope(CategoryScope scope) => switch (scope) {
        CategoryScope.got => TransactionType.got,
        CategoryScope.stock => TransactionType.purchase,
        CategoryScope.gave => TransactionType.gave,
      };
}
