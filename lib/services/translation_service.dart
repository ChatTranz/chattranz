import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const _host = 'api.mymemory.translated.net';
  static const _path = '/get';

  /// Best-effort source language detection when the API cannot accept 'auto'.
  /// Returns a 2-letter code like 'en', 'si', 'ta', or 'fr'.
  static String _detectLangCode(String text) {
    final runes = text.runes;
    // Sinhala range: U+0D80–U+0DFF
    final hasSinhala = runes.any((cp) => cp >= 0x0D80 && cp <= 0x0DFF);
    if (hasSinhala) return 'si';

    // Tamil range: U+0B80–U+0BFF
    final hasTamil = runes.any((cp) => cp >= 0x0B80 && cp <= 0x0BFF);
    if (hasTamil) return 'ta';

    // Basic French diacritics heuristic
    final hasFrenchMarks = RegExp(
      r"[àâäæçéèêëîïôœùûüÿÀÂÄÆÇÉÈÊËÎÏÔŒÙÛÜŸ]",
    ).hasMatch(text);
    if (hasFrenchMarks) return 'fr';

    // Default to English for Latin/unknown
    return 'en';
  }

  /// Translate [text] to [targetLang] (e.g., 'en', 'si', 'ta', 'fr').
  /// If [sourceLang] is 'auto' or empty, we will best-effort detect it.
  static Future<String> translateText(
    String text,
    String targetLang, {
    String sourceLang = 'auto',
  }) async {
    final src = (sourceLang.isEmpty || sourceLang.toLowerCase() == 'auto')
        ? _detectLangCode(text)
        : sourceLang;

    final uri = Uri.https(_host, _path, {
      'q': text,
      'langpair': '$src|$targetLang',
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText = data['responseData']?['translatedText'];
        if (translatedText is String && translatedText.isNotEmpty) {
          return translatedText;
        }
        // Fallback if API responds but with unexpected body
        return text;
      } else {
        // ignore: avoid_print
        print('Translation error ${response.statusCode}: ${response.body}');
        return text; // fallback to original
      }
    } catch (e) {
      // ignore: avoid_print
      print('Translation error: $e');
      return text;
    }
  }
}
