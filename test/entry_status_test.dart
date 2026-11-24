import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/providers/people_provider.dart';

ExpenseModel _entry({
  ExpenseRecordType type = ExpenseRecordType.expense,
  EntryBook book = EntryBook.shop,
  EntryStatus? status,
}) {
  return ExpenseModel(
    id: '1',
    amount: 500,
    categoryId: 'c',
    note: '',
    date: DateTime(2026, 11, 24),
    type: type,
    personId: 'ali',
    book: book,
    status: status,
  );
}

void main() {
  group('ledgerEffectOf', () {
    test('lena-dena: expense = you gave, income = you got', () {
      expect(ledgerEffectOf(_entry(book: EntryBook.people)), LedgerEffect.gave);
      expect(
        ledgerEffectOf(
          _entry(book: EntryBook.people, type: ExpenseRecordType.income),
        ),
        LedgerEffect.got,
      );
    });

    test('older shop entries keep their first meaning', () {
      expect(
        ledgerEffectOf(_entry(type: ExpenseRecordType.income)),
        LedgerEffect.got,
      );
      expect(
        ledgerEffectOf(_entry(type: ExpenseRecordType.purchase)),
        LedgerEffect.gave,
      );
    });

    test('pending sale: they owe you; pending purchase: you owe them', () {
      expect(
        ledgerEffectOf(
          _entry(type: ExpenseRecordType.income, status: EntryStatus.pending),
        ),
        LedgerEffect.gave,
      );
      expect(
        ledgerEffectOf(
          _entry(type: ExpenseRecordType.purchase, status: EntryStatus.pending),
        ),
        LedgerEffect.got,
      );
    });

    test('paid shop entries do not change the balance', () {
      expect(
        ledgerEffectOf(
          _entry(type: ExpenseRecordType.income, status: EntryStatus.paid),
        ),
        LedgerEffect.none,
      );
    });
  });

  group('status in Firestore', () {
    test('pending is saved and read back', () {
      final map = _entry(status: EntryStatus.pending).toMap();
      expect(map['status'], 'pending');
      final back = ExpenseModel.fromMap('1', map);
      expect(back.isPending, isTrue);
      expect(back.status, EntryStatus.pending);
    });

    test('older entries have no status field and count as not pending', () {
      final map = _entry().toMap();
      expect(map.containsKey('status'), isFalse);
      final back = ExpenseModel.fromMap('1', map);
      expect(back.status, isNull);
      expect(back.isPending, isFalse);
    });

    test('marking paid keeps everything else', () {
      final pending = _entry(
        type: ExpenseRecordType.income,
        status: EntryStatus.pending,
      );
      final paid = pending.copyWith(status: EntryStatus.paid);
      expect(paid.status, EntryStatus.paid);
      expect(paid.amount, 500);
      expect(paid.personId, 'ali');
      expect(paid.type, ExpenseRecordType.income);
    });
  });
}
