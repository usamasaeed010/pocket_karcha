/// An item the owner buys or sells often — used for one-tap quick picks.
class ShopItemSuggestion {
  const ShopItemSuggestion({
    required this.name,
    this.nameUr,
    this.unit,
    this.rate,
    this.categoryId,
  });

  final String name;
  final String? nameUr;

  /// Unit key from `StockUnits`.
  final String? unit;

  /// Last known rate per [unit].
  final double? rate;
  final String? categoryId;

  String label(bool urdu) => urdu && nameUr != null ? nameUr! : name;

  /// True when [other] already names this item (English or Urdu).
  bool matches(String other) {
    final key = other.trim().toLowerCase();
    return name.toLowerCase() == key ||
        (nameUr != null && nameUr!.trim() == other.trim());
  }
}

/// Generic starter items shown until the owner builds up their own history.
/// Covers common food stalls (juice, fruit chaat, burgers) but every shop can
/// type its own items — recent items replace these automatically.
abstract final class ShopItemSuggestions {
  static const List<ShopItemSuggestion> starterPurchases = [
    ShopItemSuggestion(
      name: 'Bananas',
      nameUr: 'کیلے',
      unit: 'dozen',
      categoryId: 'stock_fruits',
    ),
    ShopItemSuggestion(
      name: 'Apples',
      nameUr: 'سیب',
      unit: 'kg',
      categoryId: 'stock_fruits',
    ),
    ShopItemSuggestion(
      name: 'Mangoes',
      nameUr: 'آم',
      unit: 'kg',
      categoryId: 'stock_fruits',
    ),
    ShopItemSuggestion(
      name: 'Oranges',
      nameUr: 'مالٹے',
      unit: 'dozen',
      categoryId: 'stock_fruits',
    ),
    ShopItemSuggestion(
      name: 'Milk',
      nameUr: 'دودھ',
      unit: 'litre',
      categoryId: 'stock_dairy',
    ),
    ShopItemSuggestion(
      name: 'Sugar',
      nameUr: 'چینی',
      unit: 'kg',
      categoryId: 'stock_grocery',
    ),
    ShopItemSuggestion(
      name: 'Burger buns',
      nameUr: 'برگر بن',
      unit: 'packet',
      categoryId: 'stock_bakery',
    ),
    ShopItemSuggestion(
      name: 'Chicken',
      nameUr: 'چکن',
      unit: 'kg',
      categoryId: 'stock_meat',
    ),
    ShopItemSuggestion(
      name: 'Cooking oil',
      nameUr: 'تیل',
      unit: 'litre',
      categoryId: 'stock_grocery',
    ),
    ShopItemSuggestion(
      name: 'Eggs',
      nameUr: 'انڈے',
      unit: 'tray',
      categoryId: 'stock_dairy',
    ),
    ShopItemSuggestion(
      name: 'Ice',
      nameUr: 'برف',
      unit: 'piece',
      categoryId: 'stock_drinks',
    ),
    ShopItemSuggestion(
      name: 'Disposable glasses',
      nameUr: 'ڈسپوزیبل گلاس',
      unit: 'packet',
      categoryId: 'stock_packaging',
    ),
  ];
}
