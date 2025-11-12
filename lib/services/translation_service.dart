import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const _host = 'api.mymemory.translated.net';
  static const _path = '/get';

  /// Best-effort source language detection when the API cannot accept 'auto'.
  /// Returns a language code like 'en', 'si', 'ta', 'fr', 'zh-CN', etc.
  static String _detectLangCode(String text) {
    final runes = text.runes;
    // Sinhala range: U+0D80–U+0DFF
    final hasSinhala = runes.any((cp) => cp >= 0x0D80 && cp <= 0x0DFF);
    if (hasSinhala) return 'si';

    // Tamil range: U+0B80–U+0BFF
    final hasTamil = runes.any((cp) => cp >= 0x0B80 && cp <= 0x0BFF);
    if (hasTamil) return 'ta';

    // Devanagari (Hindi): U+0900–U+097F
    final hasDevanagari = runes.any((cp) => cp >= 0x0900 && cp <= 0x097F);
    if (hasDevanagari) return 'hi';

    // Bengali: U+0980–U+09FF
    final hasBengali = runes.any((cp) => cp >= 0x0980 && cp <= 0x09FF);
    if (hasBengali) return 'bn';

    // Arabic: U+0600–U+06FF (covers Arabic script incl. Persian/Urdu variants)
    final hasArabic = runes.any((cp) => cp >= 0x0600 && cp <= 0x06FF);
    if (hasArabic) return 'ar';

    // Cyrillic (Russian/Ukrainian/etc.): U+0400–U+04FF
    final hasCyrillic = runes.any((cp) => cp >= 0x0400 && cp <= 0x04FF);
    if (hasCyrillic) return 'ru';

    // Japanese Hiragana U+3040–U+309F, Katakana U+30A0–U+30FF
    final hasHiragana = runes.any((cp) => cp >= 0x3040 && cp <= 0x309F);
    final hasKatakana = runes.any((cp) => cp >= 0x30A0 && cp <= 0x30FF);
    if (hasHiragana || hasKatakana) return 'ja';

    // Chinese Han: U+4E00–U+9FFF
    final hasHan = runes.any((cp) => cp >= 0x4E00 && cp <= 0x9FFF);
    if (hasHan) return 'zh-CN';

    // Korean Hangul: U+AC00–U+D7AF
    final hasHangul = runes.any((cp) => cp >= 0xAC00 && cp <= 0xD7AF);
    if (hasHangul) return 'ko';

    // Thai: U+0E00–U+0E7F
    final hasThai = runes.any((cp) => cp >= 0x0E00 && cp <= 0x0E7F);
    if (hasThai) return 'th';

    // Greek: U+0370–U+03FF
    final hasGreek = runes.any((cp) => cp >= 0x0370 && cp <= 0x03FF);
    if (hasGreek) return 'el';

    // French diacritics heuristic
    final hasFrenchMarks = RegExp(
      r"[àâäæçéèêëîïôœùûüÿÀÂÄÆÇÉÈÊËÎÏÔŒÙÛÜŸ]",
    ).hasMatch(text);
    if (hasFrenchMarks) return 'fr';

    // Spanish diacritics and ñ
    final hasSpanishMarks = RegExp(r"[áéíóúñÁÉÍÓÚÑ]").hasMatch(text);
    if (hasSpanishMarks) return 'es';

    // German umlauts and ß
    final hasGermanMarks = RegExp(r"[äöüÄÖÜß]").hasMatch(text);
    if (hasGermanMarks) return 'de';

    // Portuguese diacritics (ã, õ, ç)
    final hasPortugueseMarks = RegExp(r"[ãõçÃÕÇ]").hasMatch(text);
    if (hasPortugueseMarks) return 'pt';

    // Italian common diacritics
    final hasItalianMarks = RegExp(r"[àèéìòùÀÈÉÌÒÙ]").hasMatch(text);
    if (hasItalianMarks) return 'it';

    // Turkish diacritics
    final hasTurkishMarks = RegExp(r"[ğüşıçöİĞÜŞIÇÖ]").hasMatch(text);
    if (hasTurkishMarks) return 'tr';

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
