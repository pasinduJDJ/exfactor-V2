/// String utilities used across the app
class StringUtils {
  /// Capitalize only the first letter of the given text.
  /// - If text is null or empty, returns the provided fallback (default: '').
  /// - Keeps the rest of the string as-is.
  static String capitalizeFirst(String? text, {String fallback = ''}) {
    if (text == null) return fallback;
    if (text.isEmpty) return fallback;
    if (text.length == 1) return text.toUpperCase();
    return text[0].toUpperCase() + text.substring(1);
  }
}
