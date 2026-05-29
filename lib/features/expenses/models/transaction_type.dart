/// You Gave = expense, You Got = income.
enum TransactionType {
  gave,
  got;

  bool get isIncome => this == TransactionType.got;
}
