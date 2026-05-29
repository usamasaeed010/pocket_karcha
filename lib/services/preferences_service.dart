import 'package:shared_preferences/shared_preferences.dart';

enum SessionType { none, guest, local, firebase }

class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _onboardingKey = 'onboarding_complete';
  static const _sessionTypeKey = 'session_type';
  static const _emailKey = 'user_email';
  static const _nameKey = 'user_name';
  static const _localPasswordKey = 'local_password';
  static const _userIdKey = 'user_id';
  static const _profileCompleteKey = 'profile_complete';
  static const _phoneKey = 'user_phone';
  static const _countryKey = 'user_country';
  static const _dialKey = 'user_dial';
  static const _currencyKey = 'user_currency';
  static const _avatarUrlKey = 'user_avatar_url';
  static const _localeUrduKey = 'locale_urdu';
  static const _terminologyKey = 'app_terminology';
  static const _defaultPeriodKey = 'default_period';
  static const _customCategoriesKey = 'custom_categories_v1';
  static const _peopleKey = 'people_contacts_v1';
  static const _dateRangeStartKey = 'date_range_start';
  static const _dateRangeEndKey = 'date_range_end';

  bool get onboardingComplete => _prefs.getBool(_onboardingKey) ?? false;
  bool get localeUrdu => _prefs.getBool(_localeUrduKey) ?? false;
  String? get terminologyKey => _prefs.getString(_terminologyKey);
  String? get defaultPeriodKey => _prefs.getString(_defaultPeriodKey);
  String? get customCategoriesJson => _prefs.getString(_customCategoriesKey);
  String? get peopleJson => _prefs.getString(_peopleKey);
  String? get dateRangeStart => _prefs.getString(_dateRangeStartKey);
  String? get dateRangeEnd => _prefs.getString(_dateRangeEndKey);
  bool get profileComplete => _prefs.getBool(_profileCompleteKey) ?? false;
  String? get sessionUserId => _prefs.getString(_userIdKey);
  String? get userPhone => _prefs.getString(_phoneKey);
  String? get userCurrency => _prefs.getString(_currencyKey);
  String? get avatarUrl => _prefs.getString(_avatarUrlKey);

  SessionType get sessionType {
    final raw = _prefs.getString(_sessionTypeKey);
    return SessionType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => SessionType.none,
    );
  }

  String? get userEmail => _prefs.getString(_emailKey);
  String? get userName => _prefs.getString(_nameKey);

  bool get hasActiveSession {
    final type = sessionType;
    return type == SessionType.guest ||
        type == SessionType.local ||
        type == SessionType.firebase;
  }

  Future<void> setOnboardingComplete() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  Future<void> resetOnboarding() async {
    await _prefs.setBool(_onboardingKey, false);
  }

  Future<void> setGuestSession() async {
    await _prefs.setString(_sessionTypeKey, SessionType.guest.name);
    await _clearUserData();
  }

  Future<void> setFirebaseSession({
    required String uid,
    required String email,
    String? name,
    bool profileComplete = false,
  }) async {
    await _prefs.setString(_sessionTypeKey, SessionType.firebase.name);
    await _prefs.setString(_userIdKey, uid);
    await _prefs.setString(_emailKey, email);
    if (name != null) await _prefs.setString(_nameKey, name);
    await _prefs.setBool(_profileCompleteKey, profileComplete);
    await _prefs.remove(_localPasswordKey);
  }

  Future<void> saveProfileMeta({
    required String userId,
    required String phone,
    required String countryCode,
    required String dialCode,
    required String currency,
    required bool profileComplete,
  }) async {
    await _prefs.setString(_userIdKey, userId);
    await _prefs.setString(_phoneKey, phone);
    await _prefs.setString(_countryKey, countryCode);
    await _prefs.setString(_dialKey, dialCode);
    await _prefs.setString(_currencyKey, currency);
    await _prefs.setBool(_profileCompleteKey, profileComplete);
  }

  Future<void> setAvatarUrl(String url) async {
    await _prefs.setString(_avatarUrlKey, url);
  }

  Future<void> setUserName(String name) async {
    await _prefs.setString(_nameKey, name);
  }

  Future<void> setLocaleUrdu(bool urdu) async {
    await _prefs.setBool(_localeUrduKey, urdu);
  }

  Future<void> setTerminology(String key) async {
    await _prefs.setString(_terminologyKey, key);
  }

  Future<void> setDefaultPeriod(String key) async {
    await _prefs.setString(_defaultPeriodKey, key);
  }

  Future<void> setCustomCategoriesJson(String json) async {
    await _prefs.setString(_customCategoriesKey, json);
  }

  Future<void> setPeopleJson(String json) async {
    await _prefs.setString(_peopleKey, json);
  }

  Future<void> setPeriodEnd(DateTime end) async {
    final day = DateTime(end.year, end.month, end.day);
    await _prefs.remove(_dateRangeStartKey);
    await _prefs.setString(_dateRangeEndKey, day.toIso8601String());
  }

  Future<void> setDateRange(DateTime? start, DateTime? end) async {
    if (end == null) {
      await clearDateRange();
      return;
    }
    await setPeriodEnd(end);
  }

  Future<void> clearDateRange() => setDateRange(null, null);

  Future<void> setCurrencyCode(String code) async {
    await _prefs.setString(_currencyKey, code);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_sessionTypeKey);
    await _clearUserData();
  }

  Future<void> _clearUserData() async {
    await _prefs.remove(_emailKey);
    await _prefs.remove(_nameKey);
    await _prefs.remove(_localPasswordKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_profileCompleteKey);
    await _prefs.remove(_phoneKey);
    await _prefs.remove(_countryKey);
    await _prefs.remove(_dialKey);
    await _prefs.remove(_currencyKey);
    await _prefs.remove(_avatarUrlKey);
  }

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }
}
