import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:chattranz/services/translation_service.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<dynamic> memberIds;

  const GroupChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.memberIds,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, Map<String, dynamic>> _userCache = {};
  final Map<String, Map<String, String>> _translationCache =
      {}; // messageId -> lang -> translation
  String preferredLang = 'en';

  Future<Map<String, dynamic>> _fetchUser(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid]!;
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    _userCache[uid] = data;
    return data;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final sender = _auth.currentUser;
    if (sender == null) return;
    _messageController.clear();
    await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add({
          'senderId': sender.uid,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  void _showMembersBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 400,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Group Members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.memberIds.length,
                  itemBuilder: (c, i) {
                    final id = widget.memberIds[i] as String? ?? '';
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _fetchUser(id),
                      builder: (c, snap) {
                        final data = snap.data ?? {};
                        final name =
                            (data['displayName'] ??
                                    data['name'] ??
                                    data['email'] ??
                                    'User')
                                .toString();
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text(data['email']?.toString() ?? ''),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // --- Translation setup (similar to 1:1 chat page) ---
  @override
  void initState() {
    super.initState();
    _loadPreferredLang();
  }

  Future<void> _loadPreferredLang() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final code = (doc.data()?['preferredLang'] as String?)?.trim();
      if (code != null && code.isNotEmpty) {
        setState(() => preferredLang = code);
      }
    } catch (_) {}
  }

  Future<void> _savePreferredLang(String code) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'preferredLang': code,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

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
        return TranslateLanguage.english; // fallback for Sinhala
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

  Stream<List<Map<String, dynamic>>> _translatedMessagesStream() {
    final currentUser = _auth.currentUser;
    final targetLang = preferredLang;
    return _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
          final list = await Future.wait(
            snapshot.docs.map((doc) async {
              final data = doc.data();
              final senderId = data['senderId']?.toString() ?? '';
              final original = (data['text'] ?? '').toString();
              String display = original;
              if (senderId != currentUser?.uid && original.isNotEmpty) {
                final cached = _translationCache[doc.id]?[targetLang];
                if (cached != null) {
                  display = cached;
                } else {
                  try {
                    if (_mlKitSupports(targetLang)) {
                      final translator = OnDeviceTranslator(
                        sourceLanguage: TranslateLanguage.english,
                        targetLanguage: _mapCodeToMLKit(targetLang),
                      );
                      display = await translator.translateText(original);
                    } else {
                      display = await TranslationService.translateText(
                        original,
                        targetLang,
                      );
                    }
                    _translationCache.putIfAbsent(doc.id, () => {});
                    _translationCache[doc.id]![targetLang] = display;
                  } catch (_) {
                    display = original; // fallback
                  }
                }
              }
              return {...data, 'id': doc.id, 'displayText': display};
            }),
          );
          return list;
        });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: preferredLang,
              icon: const Icon(Icons.translate, color: Colors.white),
              dropdownColor: Colors.white,
              onChanged: (val) {
                if (val == null) return;
                setState(() => preferredLang = val);
                _savePreferredLang(val);
              },
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'si', child: Text('Sinhala')),
                DropdownMenuItem(value: 'ta', child: Text('Tamil')),
                DropdownMenuItem(value: 'fr', child: Text('French')),
                DropdownMenuItem(value: 'es', child: Text('Spanish')),
                DropdownMenuItem(value: 'de', child: Text('German')),
                DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                DropdownMenuItem(value: 'zh-CN', child: Text('Chinese')),
                DropdownMenuItem(value: 'ja', child: Text('Japanese')),
                DropdownMenuItem(value: 'ar', child: Text('Arabic')),
                DropdownMenuItem(value: 'ru', child: Text('Russian')),
                DropdownMenuItem(value: 'pt', child: Text('Portuguese')),
                DropdownMenuItem(value: 'it', child: Text('Italian')),
                DropdownMenuItem(value: 'tr', child: Text('Turkish')),
                DropdownMenuItem(value: 'ur', child: Text('Urdu')),
                DropdownMenuItem(value: 'bn', child: Text('Bengali')),
                DropdownMenuItem(value: 'ko', child: Text('Korean')),
                DropdownMenuItem(value: 'vi', child: Text('Vietnamese')),
                DropdownMenuItem(value: 'id', child: Text('Indonesian')),
                DropdownMenuItem(value: 'th', child: Text('Thai')),
                DropdownMenuItem(value: 'nl', child: Text('Dutch')),
                DropdownMenuItem(value: 'el', child: Text('Greek')),
                DropdownMenuItem(value: 'sv', child: Text('Swedish')),
                DropdownMenuItem(value: 'cs', child: Text('Czech')),
                DropdownMenuItem(value: 'ro', child: Text('Romanian')),
                DropdownMenuItem(value: 'hu', child: Text('Hungarian')),
                DropdownMenuItem(value: 'sk', child: Text('Slovak')),
                DropdownMenuItem(value: 'pl', child: Text('Polish')),
                DropdownMenuItem(value: 'uk', child: Text('Ukrainian')),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Members',
            onPressed: _showMembersBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _translatedMessagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Say hello!'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final senderId = msg['senderId']?.toString() ?? '';
                    final createdAt = msg['createdAt'] as Timestamp?;
                    final isMe = senderId == currentUser?.uid;
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _fetchUser(senderId),
                      builder: (c, snap) {
                        final userData = snap.data ?? {};
                        final name =
                            (userData['displayName'] ??
                                    userData['name'] ??
                                    userData['email'] ??
                                    'User')
                                .toString();
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 320),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.blueAccent
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: isMe
                                          ? Colors.white
                                          : Colors.blueGrey,
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isMe
                                              ? Colors.blueAccent
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTime(createdAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (isMe) ...[
                                  Text(
                                    (msg['text'] ?? '').toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isMe
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    (msg['displayText'] ?? msg['text'] ?? '')
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    (msg['text'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
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
