// import 'dart:io'; // Image attachments are disabled for now.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/stock_units.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';

/// How a record is paid: settled now, still to be paid (udhaar), or a
/// personal (home) expense that goes to the personal khata.
enum RecordMode { paid, pending, personal }

class AddExpenseFormState {
  const AddExpenseFormState({
    this.categoryId = '',
    // Image attachments are disabled for now.
    // this.receiptFile,
    // this.existingReceiptUrl,
    this.saving = false,
    this.error,
    this.transactionType = TransactionType.purchase,
    this.selectedDate,
    this.personId,
    this.unit = StockUnits.defaultPurchase,
    this.showItems = true,
    this.mode = RecordMode.paid,
    this.personalCategoryId = _defaultPersonalCategory,
  });

  static const _defaultPersonalCategory = 'p_other';

  final String categoryId;
  // Image attachments are disabled for now.
  // final File? receiptFile;
  // final String? existingReceiptUrl;
  final bool saving;
  final String? error;
  final TransactionType transactionType;
  final DateTime? selectedDate;
  final String? personId;

  /// Unit key from [StockUnits] for the quantity field.
  final String unit;

  /// Whether the item / quantity / rate section is shown.
  final bool showItems;

  /// Paid, pending or personal.
  final RecordMode mode;

  /// Category used when [mode] is [RecordMode.personal].
  final String personalCategoryId;

  bool get isPersonal => mode == RecordMode.personal;

  DateTime get date => selectedDate ?? DateTime.now();

  AddExpenseFormState copyWith({
    String? categoryId,
    // File? receiptFile,
    // bool clearReceipt = false,
    // String? existingReceiptUrl,
    // bool clearExistingReceiptUrl = false,
    bool? saving,
    String? error,
    bool clearError = false,
    TransactionType? transactionType,
    DateTime? selectedDate,
    String? personId,
    bool clearPersonId = false,
    String? unit,
    bool? showItems,
    RecordMode? mode,
    String? personalCategoryId,
  }) {
    return AddExpenseFormState(
      categoryId: categoryId ?? this.categoryId,
      // receiptFile: clearReceipt ? null : (receiptFile ?? this.receiptFile),
      // existingReceiptUrl: clearExistingReceiptUrl
      //     ? null
      //     : (existingReceiptUrl ?? this.existingReceiptUrl),
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      transactionType: transactionType ?? this.transactionType,
      selectedDate: selectedDate ?? this.selectedDate,
      personId: clearPersonId ? null : (personId ?? this.personId),
      unit: unit ?? this.unit,
      showItems: showItems ?? this.showItems,
      mode: mode ?? this.mode,
      personalCategoryId: personalCategoryId ?? this.personalCategoryId,
    );
  }
}

class AddExpenseFormNotifier extends Notifier<AddExpenseFormState> {
  @override
  AddExpenseFormState build() {
    const type = TransactionType.purchase;
    return AddExpenseFormState(
      categoryId: _firstForType(type),
      transactionType: type,
      selectedDate: DateTime.now(),
    );
  }

  String _firstForType(TransactionType type) {
    return ref
            .read(categoriesRepositoryProvider)
            .firstIdForScope(type.categoryScope) ??
        '';
  }

  static String _defaultUnit(TransactionType type) =>
      type == TransactionType.got
          ? StockUnits.defaultSale
          : StockUnits.defaultPurchase;

  void setCategory(String id) {
    state = state.copyWith(categoryId: id);
  }

  // Image attachments are disabled for now.
  // void setReceipt(File? file) {
  //   state = state.copyWith(receiptFile: file, clearReceipt: file == null);
  // }

  void setTransactionType(TransactionType type) {
    if (type == state.transactionType) return;
    final firstId = _firstForType(type);
    state = state.copyWith(
      transactionType: type,
      categoryId: firstId.isNotEmpty ? firstId : state.categoryId,
      showItems: type.showsItemsByDefault,
      // A sale is never a personal expense.
      mode: type == TransactionType.got && state.isPersonal
          ? RecordMode.paid
          : null,
    );
  }

  void setMode(RecordMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setPersonalCategory(String id) {
    state = state.copyWith(personalCategoryId: id);
  }

  void setUnit(String unit) {
    state = state.copyWith(unit: unit);
  }

  void setShowItems(bool show) {
    state = state.copyWith(showItems: show);
  }

  void setPerson(String? id) {
    state = state.copyWith(personId: id, clearPersonId: id == null);
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setSaving(bool saving) {
    state = state.copyWith(saving: saving);
  }

  void setError(String? error) {
    state = state.copyWith(error: error, clearError: error == null);
  }

  void reset({
    String? categoryId,
    TransactionType? transactionType,
    String? personId,
  }) {
    final type = transactionType ?? TransactionType.purchase;
    state = AddExpenseFormState(
      categoryId: categoryId ?? _firstForType(type),
      transactionType: type,
      selectedDate: DateTime.now(),
      personId: personId,
      unit: _defaultUnit(type),
      showItems: type.showsItemsByDefault,
    );
  }

  void loadFromExpense(ExpenseModel expense) {
    final type = TransactionType.fromRecord(expense.type);
    final personal = expense.book == EntryBook.personal;
    state = AddExpenseFormState(
      categoryId: personal ? _firstForType(type) : expense.categoryId,
      mode: personal
          ? RecordMode.personal
          : (expense.isPending ? RecordMode.pending : RecordMode.paid),
      personalCategoryId: personal
          ? expense.categoryId
          : AddExpenseFormState._defaultPersonalCategory,
      transactionType: type,
      selectedDate: expense.date,
      personId: expense.personId,
      // existingReceiptUrl: expense.receiptUrl,
      unit: expense.unit ?? _defaultUnit(type),
      showItems: type.showsItemsByDefault ||
          expense.hasItemName ||
          expense.hasQuantity,
    );
  }
}

final addExpenseFormProvider =
    NotifierProvider<AddExpenseFormNotifier, AddExpenseFormState>(
  AddExpenseFormNotifier.new,
);
