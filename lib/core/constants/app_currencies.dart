class AppCurrency {
  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.nameEn,
    required this.nameUr,
    this.flag = '💱',
  });

  final String code;
  final String symbol;
  final String nameEn;
  final String nameUr;
  final String flag;

  String name(bool urdu) => urdu ? nameUr : nameEn;
}

abstract final class AppCurrencies {
  static const List<AppCurrency> all = [
    AppCurrency(
      code: 'PKR',
      symbol: 'Rs',
      nameEn: 'Pakistani Rupee',
      nameUr: 'پاکستانی روپیہ',
      flag: '🇵🇰',
    ),
    AppCurrency(
      code: 'USD',
      symbol: '\$',
      nameEn: 'US Dollar',
      nameUr: 'امریکی ڈالر',
      flag: '🇺🇸',
    ),
    AppCurrency(
      code: 'AED',
      symbol: 'د.إ',
      nameEn: 'UAE Dirham',
      nameUr: 'متحدہ عرب درہم',
      flag: '🇦🇪',
    ),
    AppCurrency(
      code: 'SAR',
      symbol: '﷼',
      nameEn: 'Saudi Riyal',
      nameUr: 'سعودی ریال',
      flag: '🇸🇦',
    ),
    AppCurrency(
      code: 'GBP',
      symbol: '£',
      nameEn: 'British Pound',
      nameUr: 'برطانوی پاؤنڈ',
      flag: '🇬🇧',
    ),
    AppCurrency(
      code: 'EUR',
      symbol: '€',
      nameEn: 'Euro',
      nameUr: 'یورو',
      flag: '🇪🇺',
    ),
    AppCurrency(
      code: 'INR',
      symbol: '₹',
      nameEn: 'Indian Rupee',
      nameUr: 'بھارتی روپیہ',
      flag: '🇮🇳',
    ),
  ];

  static AppCurrency byCode(String code) {
    return all.firstWhere(
      (c) => c.code == code,
      orElse: () => all.first,
    );
  }

  static AppCurrency forCountryCode(String iso) {
    switch (iso) {
      case 'PK':
        return all[0];
      case 'US':
        return all[1];
      case 'AE':
        return all[2];
      case 'SA':
        return all[3];
      case 'GB':
        return all[4];
      case 'IN':
        return all[6];
      default:
        return all[0];
    }
  }
}
