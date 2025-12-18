import 'package:chattranz/services/translation_service.dart';

/// Simple helper to translate an incoming message to a preferred language.
///
/// Usage:
///   await handleIncomingMessage("Hello", preferredLang: "en");
Future<void> handleIncomingMessage(
  String originalText, {
  String preferredLang = 'en',
}) async {
  final translated = await TranslationService.translateText(
    originalText,
    preferredLang,
  );
  // For now, just log both versions. In UI, use `translated` for display.
  // You can refactor this to return the string or write back to Firestore.
  // Keeping the signature to match the user's snippet.
  // ignore: avoid_print
  print('Original: $originalText');
  // ignore: avoid_print
  print('Translated: $translated');
}
