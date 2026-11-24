abstract final class AppUrls {
  static const privacyPolicy = 'https://pocket-khata033.netlify.app/';
  static const accountDeletion =
      'https://pocket-karcha-delete-form033.netlify.app/';

  static const playStore =
      'https://play.google.com/store/apps/details?id=com.pocket.karcha.expense.manager';

  /// Customer store pages are served from Firebase Hosting (`web_store/`).
  /// Override for local testing with
  /// `--dart-define=STORE_BASE_URL=http://10.0.2.2:5002`.
  static const _storeBaseOverride = String.fromEnvironment('STORE_BASE_URL');
  static const storeBase = _storeBaseOverride == ''
      ? 'https://pocket-karcha-new.web.app'
      : _storeBaseOverride;

  /// Shops with their own Hosting site: the same order page, opened at that
  /// site's root. Keep in sync with `siteShops` in `web_store/config.js` and
  /// the sites in `firebase.json`.
  static const _shopSites = {'chill-n-chaat': 'https://chill-n-chaat.web.app'};

  /// Full link a customer opens, e.g. `https://pocket-karcha-new.web.app/my-shop`
  /// (or the shop's own site).
  static String storeLink(String slug) => _storeBaseOverride.isEmpty
      ? (_shopSites[slug] ?? '$storeBase/$slug')
      : '$storeBase/$slug';

  /// Short form for display, without the scheme.
  static String storeLinkDisplay(String slug) =>
      storeLink(slug).replaceFirst(RegExp(r'^https?://'), '');

  /// Host + slash shown before the handle field.
  static String get storeHostPrefix =>
      '${storeBase.replaceFirst(RegExp(r'^https?://'), '')}/';
}
