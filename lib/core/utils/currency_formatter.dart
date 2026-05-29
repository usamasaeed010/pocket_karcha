import 'package:intl/intl.dart';
import 'package:pocket_karcha/core/constants/app_currencies.dart';

abstract final class CurrencyFormatter {
  static String format(num amount, {String currencyCode = 'PKR'}) {
    final currency = AppCurrencies.byCode(currencyCode);
    final formatter = NumberFormat.currency(
      locale: 'en',
      symbol: '${currency.symbol} ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
