import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/data/models/person_model.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';
import 'package:pocket_karcha/services/firebase_service.dart';
import 'package:pocket_karcha/services/preferences_service.dart';

/// People for the lena-dena ledger.
///
/// Signed in: `users/{uid}/people/{personId}` in Firestore, so the list
/// survives a new phone. Guest / no Firebase: saved on this phone.
class PeopleRepository {
  PeopleRepository(this._prefs, this._db);

  final PreferencesService _prefs;
  final FirebaseFirestore? _db;

  bool get hasCloud => _db != null;

  CollectionReference<Map<String, dynamic>> _people(String uid) =>
      _db!.collection('users').doc(uid).collection('people');

  // ── On this phone (guest, and older app versions) ────────────────────────

  List<PersonModel> loadLocal() {
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

  Future<void> _saveLocal(List<PersonModel> people) async {
    final json = jsonEncode(people.map((p) => p.toJson()).toList());
    await _prefs.setPeopleJson(json);
  }

  // ── Account ──────────────────────────────────────────────────────────────

  Stream<List<PersonModel>> watch(String uid) {
    return _people(uid).snapshots().map(
          (snap) => [
            for (final d in snap.docs)
              PersonModel.fromJson({...d.data(), 'id': d.id}),
          ],
        );
  }

  /// Older versions kept people only on the phone. Copy them into the
  /// account once (same ids, so running it twice changes nothing).
  Future<void> moveLocalToAccount(String uid) async {
    final local = loadLocal();
    if (local.isEmpty) return;
    final batch = _db!.batch();
    for (final p in local) {
      batch.set(_people(uid).doc(p.id), p.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
    await _prefs.clearPeopleJson();
  }

  Future<void> save(String? uid, PersonModel person) async {
    if (_db != null && uid != null) {
      await _people(uid).doc(person.id).set(person.toJson());
      return;
    }
    final list = loadLocal();
    final i = list.indexWhere((p) => p.id == person.id);
    if (i >= 0) {
      list[i] = person;
    } else {
      list.add(person);
    }
    await _saveLocal(list);
  }

  Future<void> remove(String? uid, String id) async {
    if (_db != null && uid != null) {
      await _people(uid).doc(id).delete();
      return;
    }
    await _saveLocal(loadLocal().where((p) => p.id != id).toList());
  }
}

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  return PeopleRepository(
    ref.watch(preferencesServiceProvider),
    FirebaseService.isReady ? FirebaseFirestore.instance : null,
  );
});

/// Bumped after a local (guest) change so the list reloads.
final peopleRefreshProvider = StateProvider<int>((ref) => 0);

String? _accountUid(Ref ref) {
  final guest = ref.watch(guestModeProvider);
  return guest ? null : ref.watch(currentUserIdProvider);
}

final peopleStreamProvider = StreamProvider<List<PersonModel>>((ref) {
  final repo = ref.watch(peopleRepositoryProvider);
  final uid = _accountUid(ref);
  if (uid == null || !repo.hasCloud) {
    ref.watch(peopleRefreshProvider);
    return Stream.value(repo.loadLocal());
  }
  unawaited(
    repo.moveLocalToAccount(uid).catchError(
          (Object e) => debugPrint('People move to account failed: $e'),
        ),
  );
  return repo.watch(uid);
});

/// People sorted by name.
final peopleListProvider = Provider<List<PersonModel>>((ref) {
  final people = [...?ref.watch(peopleStreamProvider).valueOrNull];
  people.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return people;
});

final personByIdProvider = Provider.family<PersonModel?, String>((ref, id) {
  return ref.watch(peopleListProvider).where((p) => p.id == id).firstOrNull;
});

/// How one entry moves the lena-dena balance with its person.
enum LedgerEffect {
  /// You gave money or goods: they owe you more.
  gave,

  /// You got money or goods: you owe them more.
  got,

  /// Paid on the spot: listed with the person, no balance.
  none,
}

/// * Lena-dena entries: `expense` = you gave, `income` = you got.
/// * Shop entries marked pending (udhaar): a sale means they owe you
///   (gave); a purchase or expense means you owe them (got).
/// * Shop entries marked paid were settled on the spot: no balance.
/// * Older shop entries (no status) keep their first meaning: sale = got,
///   purchase or expense = gave.
LedgerEffect ledgerEffectOf(ExpenseModel e) {
  if (e.book == EntryBook.people || e.status == null) {
    return e.isIncome ? LedgerEffect.got : LedgerEffect.gave;
  }
  if (e.isPending) return e.isIncome ? LedgerEffect.gave : LedgerEffect.got;
  return LedgerEffect.none;
}

/// Every person's lena-dena totals, from all entries that name them
/// (see [ledgerEffectOf]).
final ledgersProvider = Provider<Map<String, PersonLedger>>((ref) {
  final all = ref.watch(allEntriesStreamProvider).valueOrNull ?? const [];
  final gave = <String, double>{};
  final got = <String, double>{};
  final count = <String, int>{};
  final last = <String, DateTime>{};
  for (final e in all) {
    final id = e.personId;
    if (id == null || id.isEmpty) continue;
    switch (ledgerEffectOf(e)) {
      case LedgerEffect.got:
        got[id] = (got[id] ?? 0) + e.amount;
      case LedgerEffect.gave:
        gave[id] = (gave[id] ?? 0) + e.amount;
      case LedgerEffect.none:
        break;
    }
    count[id] = (count[id] ?? 0) + 1;
    final seen = last[id];
    if (seen == null || e.date.isAfter(seen)) last[id] = e.date;
  }
  return {
    for (final id in count.keys)
      id: PersonLedger(
        gave: gave[id] ?? 0,
        got: got[id] ?? 0,
        entries: count[id]!,
        lastActivity: last[id],
      ),
  };
});

final personLedgerProvider = Provider.family<PersonLedger, String>((ref, id) {
  return ref.watch(ledgersProvider)[id] ?? const PersonLedger();
});

/// Entries with one person, newest first.
final personExpensesProvider =
    Provider.family<List<ExpenseModel>, String>((ref, id) {
  final all = ref.watch(allEntriesStreamProvider).valueOrNull ?? const [];
  return all.where((e) => e.personId == id).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

/// Totals across everyone: how much you will get and how much you will give.
class PeopleSummary {
  const PeopleSummary({this.toGet = 0, this.toGive = 0});

  final double toGet;
  final double toGive;
}

final peopleSummaryProvider = Provider<PeopleSummary>((ref) {
  final ledgers = ref.watch(ledgersProvider);
  final people = ref.watch(peopleListProvider);
  var toGet = 0.0;
  var toGive = 0.0;
  for (final p in people) {
    final net = ledgers[p.id]?.net ?? 0;
    if (net > 0) {
      toGet += net;
    } else {
      toGive -= net;
    }
  }
  return PeopleSummary(toGet: toGet, toGive: toGive);
});

final peopleActionsProvider = Provider<PeopleActions>((ref) {
  return PeopleActions(ref);
});

class PeopleActions {
  PeopleActions(this._ref);
  final Ref _ref;

  String? get _uid {
    final guest = _ref.read(guestModeProvider);
    return guest ? null : _ref.read(currentUserIdProvider);
  }

  void _refreshLocal() => _ref.read(peopleRefreshProvider.notifier).state++;

  /// Adds a person, or updates them when the id already exists.
  Future<void> add(PersonModel person) async {
    await _ref.read(peopleRepositoryProvider).save(_uid, person);
    _refreshLocal();
  }

  Future<void> update(PersonModel person) => add(person);

  /// Removes the person and their lena-dena entries. Older shop entries
  /// that named them stay in the shop khata, just without the name.
  Future<void> removeWithEntries(String id) async {
    final actions = _ref.read(expenseActionsProvider);
    final entries = _ref.read(personExpensesProvider(id));
    // Start every write at once: Firestore applies them on the phone right
    // away, even offline, and syncs them later.
    final writes = <Future<void>>[
      for (final e in entries)
        if (e.book == EntryBook.people)
          actions.delete(e.id)
        else
          actions.update(e.copyWith(clearPersonId: true)),
      _ref.read(peopleRepositoryProvider).remove(_uid, id),
    ];
    await Future.wait(writes);
    _refreshLocal();
  }

  Future<void> remove(String id) => removeWithEntries(id);
}
