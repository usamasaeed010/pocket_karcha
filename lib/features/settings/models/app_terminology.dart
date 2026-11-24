/// Labels used for money in / money out entries.
///
/// Purchases (stock) are always called "Purchase" / "خریداری".
enum AppTerminology {
  shop,
  gotGave,
  creditDebit,
  cashInOut,
  incomeExpense;

  String get storageKey => name;

  static AppTerminology fromKey(String? key) {
    return AppTerminology.values.firstWhere(
      (e) => e.name == key,
      orElse: () => AppTerminology.shop,
    );
  }

  String label(bool urdu) {
    switch (this) {
      case AppTerminology.shop:
        return urdu ? 'فروخت - خرچہ' : 'Sale - Expense';
      case AppTerminology.gotGave:
        return urdu ? 'ملے - دیے' : 'Got - Gave';
      case AppTerminology.creditDebit:
        return urdu ? 'کریڈٹ - ڈیبٹ' : 'Credit - Debit';
      case AppTerminology.cashInOut:
        return urdu ? 'کیش ان - آؤٹ' : 'Cash In - Cash Out';
      case AppTerminology.incomeExpense:
        return urdu ? 'آمدنی - خرچ' : 'Income - Expense';
    }
  }

  ({String positive, String negative}) pair(bool urdu) {
    switch (this) {
      case AppTerminology.shop:
        return (
          positive: urdu ? 'فروخت' : 'Sale',
          negative: urdu ? 'خرچہ' : 'Expense',
        );
      case AppTerminology.gotGave:
        return (
          positive: urdu ? 'آمدنی' : 'You Got',
          negative: urdu ? 'خرچ' : 'You Gave',
        );
      case AppTerminology.creditDebit:
        return (
          positive: urdu ? 'کریڈٹ' : 'Credit',
          negative: urdu ? 'ڈیبٹ' : 'Debit',
        );
      case AppTerminology.cashInOut:
        return (
          positive: urdu ? 'کیش ان' : 'Cash In',
          negative: urdu ? 'کیش آؤٹ' : 'Cash Out',
        );
      case AppTerminology.incomeExpense:
        return (
          positive: urdu ? 'آمدنی' : 'Income',
          negative: urdu ? 'خرچ' : 'Expense',
        );
    }
  }
}
