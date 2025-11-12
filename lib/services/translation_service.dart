import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const _baseUrl = 'https://api.mymemory.translated.net/get';

  /// Translate text to a target language (e.g., 'en' or 'si')
  static Future<String> translateText(String text, String targetLang,
      {String sourceLang = 'auto'}) async {
    final uri = Uri.parse('$_baseUrl?q=$text&langpair=$sourceLang|$targetLang');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText = data['responseData']['translatedText'];
        return translatedText;
      } else {
        print('Error ${response.statusCode}: ${response.body}');
        return text; // fallback
      }
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }
}
