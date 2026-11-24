// import 'dart:io'; // Image attachments are disabled for now.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/utils/date_utils.dart';
import 'package:pocket_karcha/data/datasources/pk_expense_suggestions.dart';
import 'package:pocket_karcha/data/datasources/shop_item_suggestions.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/data/models/expense_suggestion.dart';
import 'package:pocket_karcha/data/repositories/expense_repository.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/firebase_providers.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final repo = ExpenseRepository(
    firestore: ref.watch(firestoreServiceProvider),
    // Image attachments are disabled for now — no receipt uploads.
    // storage: ref.watch(storageServiceProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Every entry: shop, personal and lena-dena (newest first).
final allEntriesStreamProvider = StreamProvider<List<ExpenseModel>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final guest = ref.watch(guestModeProvider);
  final effectiveUid = guest ? null : uid;
  return ref.watch(expenseRepositoryProvider).watch(effectiveUid);
});

/// Shop entries only (sales, purchases, shop expenses). The shop khata,
/// reports, charts and budget read this, so personal and lena-dena entries
/// never change shop totals or profit.
final expensesStreamProvider = Provider<AsyncValue<List<ExpenseModel>>>((ref) {
  return ref.watch(allEntriesStreamProvider).whenData(
        (all) => all.where((e) => e.book == EntryBook.shop).toList(),
      );
});

/// Money out (purchases + expenses) in the current month.
final monthTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return expenses
      .where((e) => AppDateUtils.isSameMonth(e.date, now) && e.isOutflow)
      .fold<double>(0, (sum, e) => sum + e.amount);
});

final suggestionsProvider = FutureProvider<List<ExpenseSuggestion>>((ref) {
  return PkExpenseSuggestions.load();
});

/// Quick-pick items for the add screen: the owner's recent items first
/// (latest rate and unit), then generic starters for purchases.
final itemSuggestionsProvider =
    Provider.family<List<ShopItemSuggestion>, TransactionType>((ref, type) {
  const maxItems = 12;
  final all = ref.watch(expensesStreamProvider).valueOrNull ?? const [];
  final record = type.recordType;
  final history = all.where((e) => e.type == record && e.hasItemName).toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final seen = <String>{};
  final out = <ShopItemSuggestion>[];
  for (final e in history) {
    final name = e.itemName!.trim();
    if (!seen.add(name.toLowerCase())) continue;
    out.add(
      ShopItemSuggestion(
        name: name,
        unit: e.unit,
        rate: e.unitPrice,
        categoryId: e.categoryId,
      ),
    );
    if (out.length >= maxItems) return out;
  }

  if (type == TransactionType.purchase) {
    for (final starter in ShopItemSuggestions.starterPurchases) {
      if (out.any((s) => starter.matches(s.name))) continue;
      out.add(starter);
      if (out.length >= maxItems) break;
    }
  }
  return out;
});

final expenseActionsProvider = Provider<ExpenseActions>((ref) {
  return ExpenseActions(ref);
});

class ExpenseActions {
  ExpenseActions(this._ref);

  final Ref _ref;

  Future<void> add(ExpenseModel expense) async {
    final uid = _ref.read(currentUserIdProvider);
    final guest = _ref.read(guestModeProvider);
    await _ref.read(expenseRepositoryProvider).add(
          guest ? null : uid,
          expense,
          // Image attachments are disabled for now.
          // receiptFile: receiptFile,
        );
  }

  Future<void> update(ExpenseModel expense) async {
    final uid = _ref.read(currentUserIdProvider);
    final guest = _ref.read(guestModeProvider);
    await _ref.read(expenseRepositoryProvider).update(
          guest ? null : uid,
          expense,
          // Image attachments are disabled for now.
          // receiptFile: receiptFile,
        );
  }

  Future<void> delete(String id) async {
    final uid = _ref.read(currentUserIdProvider);
    final guest = _ref.read(guestModeProvider);
    await _ref.read(expenseRepositoryProvider).delete(guest ? null : uid, id);
  }
}
