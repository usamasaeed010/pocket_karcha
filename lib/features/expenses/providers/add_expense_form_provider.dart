import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/data/models/category_model.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';

class AddExpenseFormState {
  const AddExpenseFormState({
    this.categoryId = '',
    this.receiptFile,
    this.saving = false,
    this.error,
    this.transactionType = TransactionType.gave,
    this.selectedDate,
    this.personId,
  });

  final String categoryId;
  final File? receiptFile;
  final bool saving;
  final String? error;
  final TransactionType transactionType;
  final DateTime? selectedDate;
  final String? personId;

  DateTime get date => selectedDate ?? DateTime.now();

  AddExpenseFormState copyWith({
    String? categoryId,
    File? receiptFile,
    bool clearReceipt = false,
    bool? saving,
    String? error,
    bool clearError = false,
    TransactionType? transactionType,
    DateTime? selectedDate,
    String? personId,
    bool clearPersonId = false,
  }) {
    return AddExpenseFormState(
      categoryId: categoryId ?? this.categoryId,
      receiptFile: clearReceipt ? null : (receiptFile ?? this.receiptFile),
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      transactionType: transactionType ?? this.transactionType,
      selectedDate: selectedDate ?? this.selectedDate,
      personId: clearPersonId ? null : (personId ?? this.personId),
    );
  }
}

class AddExpenseFormNotifier extends Notifier<AddExpenseFormState> {
  @override
  AddExpenseFormState build() {
    final firstId = ref.read(categoriesRepositoryProvider).firstIdForScope(
          CategoryScope.gave,
        );
    return AddExpenseFormState(
      categoryId: firstId ?? '',
      selectedDate: DateTime.now(),
    );
  }

  String _firstForType(TransactionType type) {
    final scope =
        type == TransactionType.got ? CategoryScope.got : CategoryScope.gave;
    return ref.read(categoriesRepositoryProvider).firstIdForScope(scope) ?? '';
  }

  void setCategory(String id) {
    state = state.copyWith(categoryId: id);
  }

  void setReceipt(File? file) {
    state = state.copyWith(receiptFile: file, clearReceipt: file == null);
  }

  void setTransactionType(TransactionType type) {
    final firstId = _firstForType(type);
    state = state.copyWith(
      transactionType: type,
      categoryId: firstId.isNotEmpty ? firstId : state.categoryId,
    );
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
    final type = transactionType ?? TransactionType.gave;
    final resolvedCategory = categoryId ??
        _firstForType(type);
    state = AddExpenseFormState(
      categoryId: resolvedCategory,
      transactionType: type,
      selectedDate: DateTime.now(),
      personId: personId,
    );
  }
}

final addExpenseFormProvider =
    NotifierProvider<AddExpenseFormNotifier, AddExpenseFormState>(
  AddExpenseFormNotifier.new,
);
