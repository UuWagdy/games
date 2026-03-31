
/// Utility class for Arabic text processing and normalization.
class ArabicUtils {
  /// Normalizes Arabic text to improve matching by removing diacritics
  /// and standardizing characters like Alef and Teh Marbuta.
  static String normalize(String text) {
    if (text.isEmpty) return text;

    String normalized = text.trim();

    // Remove diacritics (Harakat)
    normalized = normalized.replaceAll(RegExp(r'[\u064B-\u0652]'), '');

    // Standardize Alefs
    normalized = normalized.replaceAll(RegExp(r'[أإآ]'), 'ا');

    // Standardize Teh Marbuta to Heh
    normalized = normalized.replaceAll('ة', 'ه');

    // Standardize Yeh to Alef Maksura (optional, depending on use case)
    // For city names, usually "ى" vs "ي" is common
    normalized = normalized.replaceAll('ى', 'ي');

    return normalized.toLowerCase();
  }

  /// Compares two Arabic strings after normalization.
  static bool areEqual(String a, String b) {
    return normalize(a) == normalize(b);
  }

  /// Checks if one Arabic string contains another after normalization.
  static bool contains(String text, String search) {
    return normalize(text).contains(normalize(search));
  }
}
