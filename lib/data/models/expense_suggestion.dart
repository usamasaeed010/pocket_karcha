class ExpenseSuggestion {
  const ExpenseSuggestion({
    required this.titleEn,
    required this.titleUr,
    required this.categoryId,
    required this.amount,
  });

  final String titleEn;
  final String titleUr;
  final String categoryId;
  final double amount;

  String title(bool urdu) => urdu ? titleUr : titleEn;
}
