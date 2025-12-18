import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:chattranz/services/translation_service.dart';

class ChatPage extends StatefulWidget {
  final String friendId;
  final String friendName;

  const ChatPage({super.key, required this.friendId, required this.friendName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool showAttachmentOptions = false;
  // User's preferred language code for receive-side translation
  // Examples: 'en' (English), 'si' (Sinhala), 'ta' (Tamil), 'fr' (French)
  String preferredLang = 'en';
  // Simple in-memory cache: messageId -> { langCode: translatedText }
  final Map<String, Map<String, String>> _translationCache = {};
  late String chatId;

  @override
  void initState() {
    super.initState();
    final currentUser = _auth.currentUser!;
    chatId = getChatId(currentUser.uid, widget.friendId);
    _loadPreferredLang();
  }

  String getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode ? '$user1-$user2' : '$user2-$user1';
  }

  // 🔹 Load preferred language code from Firestore (users/{uid}.preferredLang)
  Future<void> _loadPreferredLang() async {
    final uid = _auth.currentUser!.uid;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        final code = (data?['preferredLang'] as String?)?.trim();
        if (code != null && code.isNotEmpty) {
          setState(() => preferredLang = code);
        }
      }
    } catch (_) {
      // ignore errors; keep default 'en'
    }
  }

  // 🔹 Save preferred language code to Firestore
  Future<void> _savePreferredLang(String code) async {
    final uid = _auth.currentUser!.uid;
    try {
      await _firestore.collection('users').doc(uid).set({
        'preferredLang': code,
      }, SetOptions(merge: true));
    } catch (_) {
      // optional: show a snackbar/toast on error
    }
  }

  // 🔹 Map language code to ML Kit enum for on-send translation
  TranslateLanguage _mapCodeToMLKit(String code) {
    switch (code) {
      case 'zh':
      case 'zh-CN':
        return TranslateLanguage.chinese;
      case 'es':
        return TranslateLanguage.spanish;
      case 'de':
        return TranslateLanguage.german;
      case 'hi':
        return TranslateLanguage.hindi;
      case 'ja':
        return TranslateLanguage.japanese;
      case 'ar':
        return TranslateLanguage.arabic;
      case 'ru':
        return TranslateLanguage.russian;
      case 'pt':
        return TranslateLanguage.portuguese;
      case 'it':
        return TranslateLanguage.italian;
      case 'tr':
        return TranslateLanguage.turkish;
      case 'ur':
        return TranslateLanguage.urdu;
      case 'bn':
        return TranslateLanguage.bengali;
      case 'ko':
        return TranslateLanguage.korean;
      case 'vi':
        return TranslateLanguage.vietnamese;
      case 'id':
        return TranslateLanguage.indonesian;
      case 'th':
        return TranslateLanguage.thai;
      case 'uk':
        return TranslateLanguage.ukrainian;
      case 'pl':
        return TranslateLanguage.polish;
      case 'nl':
        return TranslateLanguage.dutch;
      case 'el':
        return TranslateLanguage.greek;
      case 'sv':
        return TranslateLanguage.swedish;
      case 'cs':
        return TranslateLanguage.czech;
      case 'ro':
        return TranslateLanguage.romanian;
      case 'hu':
        return TranslateLanguage.hungarian;
      case 'sk':
        return TranslateLanguage.slovak;
      case 'te':
        return TranslateLanguage.telugu;
      case 'kn':
        return TranslateLanguage.kannada;
      case 'gu':
        return TranslateLanguage.gujarati;
      case 'mr':
        return TranslateLanguage.marathi;
      case 'ta':
        return TranslateLanguage.tamil;
      case 'fr':
        return TranslateLanguage.french;
      case 'si':
        // Sinhala not supported on-device; fallback to English
        return TranslateLanguage.english;
      case 'en':
      default:
        return TranslateLanguage.english;
    }
  }

  bool _mlKitSupports(String code) {
    switch (code) {
      case 'en':
      case 'zh':
      case 'zh-CN':
      case 'es':
      case 'de':
      case 'hi':
      case 'ja':
      case 'ar':
      case 'ru':
      case 'pt':
      case 'it':
      case 'tr':
      case 'ur':
      case 'bn':
      case 'ko':
      case 'vi':
      case 'id':
      case 'th':
      case 'uk':
      case 'pl':
      case 'nl':
      case 'el':
      case 'sv':
      case 'cs':
      case 'ro':
      case 'hu':
      case 'sk':
      case 'te':
      case 'kn':
      case 'gu':
      case 'mr':
      case 'ta':
      case 'fr':
        return true;
      case 'si':
      default:
        return false;
    }
  }

  Future<String> _getUserPreferredLang(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        final code = (data?['preferredLang'] as String?)?.trim();
        if (code != null && code.isNotEmpty) return code;
      }
    } catch (_) {}
    return 'en';
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final currentUser = _auth.currentUser!;
    final timestamp = FieldValue.serverTimestamp();

    // 🔹 Determine friend's preferred language and translate accordingly
    final friendLang = await _getUserPreferredLang(widget.friendId);
    String translatedText = text;
    try {
      if (_mlKitSupports(friendLang)) {
        final translator = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.english,
          targetLanguage: _mapCodeToMLKit(friendLang),
        );
        translatedText = await translator.translateText(text);
      } else {
        // Fallback to network API for unsupported languages (e.g., Sinhala)
        translatedText = await TranslationService.translateText(
          text,
          friendLang,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print("Translation error: $e");
    }

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': currentUser.uid,
          'receiverId': widget.friendId,
          'text': text,
          'translatedText': translatedText,
          'timestamp': timestamp,
          'messageType': 'text',
        });

    _messageController.clear();
  }

  // 🔹 Stream that enriches messages with receiver-side translation for display
  Stream<List<Map<String, dynamic>>> _translatedMessagesStream(
    String chatId,
    String preferredLang,
  ) {
    final currentUser = _auth.currentUser!;
    final targetLang = preferredLang; // already a code like 'en','si','ta','fr'

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final docs = snapshot.docs;
          // Translate only incoming messages; keep own messages as-is
          final results = await Future.wait(
            docs.map((doc) async {
              final data = doc.data();
              final isMe = data['senderId'] == currentUser.uid;
              final original = (data['text'] ?? '').toString();
              final messageId = doc.id;

              String display = original;
              if (!isMe && original.isNotEmpty) {
                // Check in-memory cache first
                final cached = _translationCache[messageId]?[targetLang];
                if (cached != null) {
                  display = cached;
                } else {
                  try {
                    display = await TranslationService.translateText(
                      original,
                      targetLang,
                    );
                    _translationCache.putIfAbsent(messageId, () => {});
                    _translationCache[messageId]![targetLang] = display;
                  } catch (e) {
                    display = original;
                  }
                }
              }

              return {...data, 'id': messageId, 'displayText': display};
            }),
          );
          return results;
        });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            // 🔹 Row 1: Back, Message title, menu
            Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                top: 12,
                bottom: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      "Message",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 🔹 Row 2: Profile, name, language, call
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0xFF252525),
                      backgroundImage: NetworkImage(
                        "https://i.pravatar.cc/150?img=3",
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.friendName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "Online",
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.03),
                          offset: const Offset(-2, -2),
                          blurRadius: 4,
                        ),
                        const BoxShadow(
                          color: Colors.black87,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: preferredLang,
                        dropdownColor: const Color(0xFF252525),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        icon: const Icon(
                          Icons.language,
                          color: Color(0xFFFF4757),
                          size: 20,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        onChanged: (String? newLang) {
                          if (newLang == null) return;
                          setState(() => preferredLang = newLang);
                          _savePreferredLang(newLang);
                        },
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'si', child: Text('Sinhala')),
                          DropdownMenuItem(value: 'ta', child: Text('Tamil')),
                          DropdownMenuItem(value: 'fr', child: Text('French')),
                          DropdownMenuItem(value: 'es', child: Text('Spanish')),
                          DropdownMenuItem(value: 'de', child: Text('German')),
                          DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                          DropdownMenuItem(
                            value: 'zh-CN',
                            child: Text('Chinese (Simplified)'),
                          ),
                          DropdownMenuItem(
                            value: 'ja',
                            child: Text('Japanese'),
                          ),
                          DropdownMenuItem(value: 'ar', child: Text('Arabic')),
                          DropdownMenuItem(value: 'ru', child: Text('Russian')),
                          DropdownMenuItem(
                            value: 'pt',
                            child: Text('Portuguese'),
                          ),
                          DropdownMenuItem(value: 'it', child: Text('Italian')),
                          DropdownMenuItem(value: 'tr', child: Text('Turkish')),
                          DropdownMenuItem(value: 'ur', child: Text('Urdu')),
                          DropdownMenuItem(value: 'bn', child: Text('Bengali')),
                          DropdownMenuItem(value: 'ko', child: Text('Korean')),
                          DropdownMenuItem(
                            value: 'vi',
                            child: Text('Vietnamese'),
                          ),
                          DropdownMenuItem(
                            value: 'id',
                            child: Text('Indonesian'),
                          ),
                          DropdownMenuItem(value: 'th', child: Text('Thai')),
                          DropdownMenuItem(value: 'nl', child: Text('Dutch')),
                          DropdownMenuItem(value: 'el', child: Text('Greek')),
                          DropdownMenuItem(value: 'sv', child: Text('Swedish')),
                          DropdownMenuItem(value: 'cs', child: Text('Czech')),
                          DropdownMenuItem(
                            value: 'ro',
                            child: Text('Romanian'),
                          ),
                          DropdownMenuItem(
                            value: 'hu',
                            child: Text('Hungarian'),
                          ),
                          DropdownMenuItem(value: 'sk', child: Text('Slovak')),
                          DropdownMenuItem(value: 'pl', child: Text('Polish')),
                          DropdownMenuItem(
                            value: 'uk',
                            child: Text('Ukrainian'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.call, color: Color(0xFFFF4757)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _translatedMessagesStream(chatId, preferredLang),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isMe
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFF4757),
                                    Color(0xFFFF6B7A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isMe ? null : const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: isMe
                            ? // Sender's own message: show only the original text
                              Text(
                                (msg['text'] ?? '').toString(),
                                style: const TextStyle(color: Colors.white),
                              )
                            : // Received message: show translated main + original small
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (msg['displayText'] ?? msg['text'] ?? '')
                                        .toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (msg['text'] ?? '').toString(),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 🔹 Message input
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFFFF4757),
                    ),
                    onPressed: () {
                      setState(() {
                        showAttachmentOptions = !showAttachmentOptions;
                      });
                    },
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.03),
                            offset: const Offset(-2, -2),
                            blurRadius: 4,
                          ),
                          const BoxShadow(
                            color: Colors.black87,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Type a message...",
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4757).withOpacity(0.5),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => sendMessage(_messageController.text),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
