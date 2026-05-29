import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/utils/date_utils.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/data/models/expense_suggestion.dart';
import 'package:pocket_karcha/data/datasources/pk_expense_suggestions.dart';
import 'package:pocket_karcha/data/repositories/expense_repository.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/firebase_providers.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final repo = ExpenseRepository(
    firestore: ref.watch(firestoreServiceProvider),
    storage: ref.watch(storageServiceProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final expensesStreamProvider = StreamProvider<List<ExpenseModel>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final guest = ref.watch(guestModeProvider);
  final effectiveUid = guest ? null : uid;
  return ref.watch(expenseRepositoryProvider).watch(effectiveUid);
});

final monthTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return expenses
      .where((e) => AppDateUtils.isSameMonth(e.date, now) && !e.isIncome)
      .fold<double>(0, (sum, e) => sum + e.amount);
});

final suggestionsProvider = FutureProvider<List<ExpenseSuggestion>>((ref) {
  return PkExpenseSuggestions.load();
});

final expenseActionsProvider = Provider<ExpenseActions>((ref) {
  return ExpenseActions(ref);
});

class ExpenseActions {
  ExpenseActions(this._ref);

  final Ref _ref;

  Future<void> add(ExpenseModel expense, {File? receiptFile}) async {
    final uid = _ref.read(currentUserIdProvider);
    final guest = _ref.read(guestModeProvider);
    await _ref.read(expenseRepositoryProvider).add(
          guest ? null : uid,
          expense,
          receiptFile: receiptFile,
        );
  }

  Future<void> delete(String id) async {
    final uid = _ref.read(currentUserIdProvider);
    final guest = _ref.read(guestModeProvider);
    await _ref.read(expenseRepositoryProvider).delete(guest ? null : uid, id);
  }
}
