/// Store link handles: lowercase a–z, 0–9 and dashes, 3–40 chars,
/// starting and ending with a letter or digit (matches firestore.rules).
abstract final class SlugUtils {
  static final _valid = RegExp(r'^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$');

  static const reserved = {
    'admin',
    'api',
    'app',
    'help',
    'index',
    'login',
    'privacy',
    'store',
    'support',
    'terms',
    'www',
  };

  static bool isValid(String slug) =>
      _valid.hasMatch(slug) && !slug.contains('--') && !reserved.contains(slug);

  /// "Anaya's Gift Studio!" → "anayas-gift-studio".
  static String slugify(String input) {
    var s = input.toLowerCase().trim();
    s = s.replaceAll(RegExp(r"['’`]"), '');
    s = s.replaceAll('&', ' and ');
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    s = s.replaceAll(RegExp(r'-+'), '-');
    s = s.replaceAll(RegExp(r'^-|-$'), '');
    if (s.length > 40) {
      s = s.substring(0, 40).replaceAll(RegExp(r'-$'), '');
    }
    return s;
  }

  /// Slug from the name, or "shop-1234" when the name has no Latin letters.
  static String suggest(String name, {int? seed}) {
    final s = slugify(name);
    if (s.length >= 3 && !reserved.contains(s)) return s;
    final n = (seed ?? DateTime.now().millisecondsSinceEpoch) % 9000 + 1000;
    return s.isEmpty ? 'shop-$n' : '$s-shop-$n';
  }

  /// Cleans what the user types in the handle field.
  static String sanitizeTyping(String input) {
    var s = input.toLowerCase().replaceAll(' ', '-');
    s = s.replaceAll(RegExp(r'[^a-z0-9-]'), '');
    s = s.replaceAll(RegExp(r'-{2,}'), '-');
    if (s.length > 40) s = s.substring(0, 40);
    return s;
  }
}
