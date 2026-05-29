import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/data/models/person_model.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';
import 'package:pocket_karcha/services/preferences_service.dart';

class PeopleRepository {
  PeopleRepository(this._prefs);

  final PreferencesService _prefs;

  List<PersonModel> load() {
    final raw = _prefs.peopleJson;
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PersonModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<PersonModel> people) async {
    final json = jsonEncode(people.map((p) => p.toJson()).toList());
    await _prefs.setPeopleJson(json);
  }
}

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  return PeopleRepository(ref.watch(preferencesServiceProvider));
});

final peopleRefreshProvider = StateProvider<int>((ref) => 0);

final peopleListProvider = Provider<List<PersonModel>>((ref) {
  ref.watch(peopleRefreshProvider);
  return ref.watch(peopleRepositoryProvider).load();
});

final personByIdProvider = Provider.family<PersonModel?, String>((ref, id) {
  return ref.watch(peopleListProvider).where((p) => p.id == id).firstOrNull;
});

final personLedgerProvider = Provider.family<PersonLedger, String>((ref, id) {
  final expenses = ref.watch(expensesStreamProvider).valueOrNull ?? [];
  var credit = 0.0;
  var debit = 0.0;
  for (final e in expenses) {
    if (e.personId != id) continue;
    if (e.isIncome) {
      credit += e.amount;
    } else {
      debit += e.amount;
    }
  }
  return PersonLedger(credit: credit, debit: debit);
});

final personExpensesProvider =
    Provider.family<List<ExpenseModel>, String>((ref, id) {
  final expenses = ref.watch(expensesStreamProvider).valueOrNull ?? [];
  return expenses.where((e) => e.personId == id).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

final peopleActionsProvider = Provider<PeopleActions>((ref) {
  return PeopleActions(ref);
});

class PeopleActions {
  PeopleActions(this._ref);
  final Ref _ref;

  Future<void> add(PersonModel person) async {
    final repo = _ref.read(peopleRepositoryProvider);
    final existing = repo.load();
    if (existing.any((p) => p.id == person.id)) return;
    await repo.save([...existing, person]);
    _ref.read(peopleRefreshProvider.notifier).state++;
  }

  Future<void> remove(String id) async {
    final repo = _ref.read(peopleRepositoryProvider);
    await repo.save(repo.load().where((p) => p.id != id).toList());
    _ref.read(peopleRefreshProvider.notifier).state++;
  }
}
