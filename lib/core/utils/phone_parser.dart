class ParsedPhone {
  const ParsedPhone({
    required this.countryCode,
    required this.dialCode,
    required this.localNumber,
  });

  final String countryCode;
  final String dialCode;
  final String localNumber;

  String get fullNumber =>
      localNumber.isEmpty ? '' : '$dialCode$localNumber';
}

abstract final class PhoneParser {
  static const _dialToCountry = <String, String>{
    '+971': 'AE',
    '+966': 'SA',
    '+92': 'PK',
    '+91': 'IN',
    '+44': 'GB',
    '+1': 'US',
    '+61': 'AU',
    '+49': 'DE',
    '+33': 'FR',
  };

  static ParsedPhone parse(
    String? raw, {
    String defaultCountry = 'PK',
    String defaultDial = '+92',
  }) {
    if (raw == null || raw.trim().isEmpty) {
      return ParsedPhone(
        countryCode: defaultCountry,
        dialCode: defaultDial,
        localNumber: '',
      );
    }

    var value = raw.trim().replaceAll(RegExp(r'[\s\-().]'), '');

    if (value.startsWith('+')) {
      final dialCodes = _dialToCountry.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      for (final dial in dialCodes) {
        if (value.startsWith(dial)) {
          var local = value.substring(dial.length);
          if (dial == '+92' && local.startsWith('0')) {
            local = local.substring(1);
          }
          return ParsedPhone(
            countryCode: _dialToCountry[dial]!,
            dialCode: dial,
            localNumber: local.replaceAll(RegExp(r'\D'), ''),
          );
        }
      }
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92') && digits.length > 10) {
      var local = digits.substring(2);
      if (local.startsWith('0')) local = local.substring(1);
      return ParsedPhone(
        countryCode: 'PK',
        dialCode: '+92',
        localNumber: local,
      );
    }

    if (digits.startsWith('0') && digits.length >= 10) {
      return ParsedPhone(
        countryCode: defaultCountry,
        dialCode: defaultDial,
        localNumber: digits.substring(1),
      );
    }

    return ParsedPhone(
      countryCode: defaultCountry,
      dialCode: defaultDial,
      localNumber: digits,
    );
  }
}
