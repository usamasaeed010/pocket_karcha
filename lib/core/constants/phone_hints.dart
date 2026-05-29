abstract final class PhoneHints {
  static String hintForCountry(String isoCode, bool urdu) {
    switch (isoCode) {
      case 'PK':
        return urdu ? 'مثال: 300 1234567' : 'e.g. 300 1234567';
      case 'IN':
        return urdu ? 'مثال: 98765 43210' : 'e.g. 98765 43210';
      case 'US':
      case 'CA':
        return urdu ? 'مثال: 202 555 0123' : 'e.g. 202 555 0123';
      case 'AE':
      case 'SA':
        return urdu ? 'مثال: 50 123 4567' : 'e.g. 50 123 4567';
      case 'GB':
        return urdu ? 'مثال: 7700 900123' : 'e.g. 7700 900123';
      default:
        return urdu ? 'موبائل نمبر درج کریں' : 'Enter mobile number';
    }
  }

  static String label(bool urdu) =>
      urdu ? 'موبائل نمبر' : 'Mobile number';

  static int? maxLengthForCountry(String isoCode) {
    switch (isoCode) {
      case 'PK':
        return 10;
      case 'IN':
        return 10;
      case 'US':
        return 10;
      default:
        return 15;
    }
  }
}
