import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:chattranz/services/translation_service.dart';
import 'package:chattranz/services/group_service.dart';

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
  bool _isPinned = false;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userDocStream;

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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF0D0D0D),
              offset: Offset(0, -8),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 400,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Group Members',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF0D0D0D),
                              offset: Offset(3, 3),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Color(0xFF2F2F2F),
                              offset: Offset(-3, -3),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0D0D0D),
                        Color(0xFF2F2F2F),
                        Color(0xFF0D0D0D),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
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
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF0D0D0D),
                                  offset: Offset(4, 4),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Color(0xFF2F2F2F),
                                  offset: Offset(-4, -4),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1E1E1E),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xFF0D0D0D),
                                      offset: Offset(3, 3),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: Color(0xFF2F2F2F),
                                      offset: Offset(-3, -3),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                data['email']?.toString() ?? '',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
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
    _listenPinnedStatus();
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
      final pinnedList = List<String>.from(doc.data()?['pinnedGroups'] ?? []);
      _isPinned = pinnedList.contains(widget.groupId);
    } catch (_) {}
  }

  void _listenPinnedStatus() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _userDocStream = _firestore.collection('users').doc(uid).snapshots();
    _userDocStream!.listen((doc) {
      final pinnedList = List<String>.from(doc.data()?['pinnedGroups'] ?? []);
      final pinned = pinnedList.contains(widget.groupId);
      if (mounted && pinned != _isPinned) {
        setState(() => _isPinned = pinned);
      }
    });
  }

  Future<void> _togglePin() async {
    if (_isPinned) {
      await GroupService.unpinGroup(widget.groupId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Group unpinned')));
      }
    } else {
      await GroupService.pinGroup(widget.groupId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Group pinned')));
      }
    }
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
                  bool success = false;
                  // First attempt on-device translation (if supported)
                  if (_mlKitSupports(targetLang)) {
                    try {
                      final translator = OnDeviceTranslator(
                        sourceLanguage: TranslateLanguage.english,
                        targetLanguage: _mapCodeToMLKit(targetLang),
                      );
                      final translated = await translator.translateText(
                        original,
                      );
                      await translator.close();
                      if (translated.isNotEmpty && translated != original) {
                        display = translated;
                        success = true;
                      }
                    } catch (_) {
                      success = false;
                    }
                  }
                  // Fallback to network translation service if on-device failed or unsupported
                  if (!success) {
                    try {
                      final translated = await TranslationService.translateText(
                        original,
                        targetLang,
                      );
                      if (translated.isNotEmpty) {
                        display = translated;
                        success = true;
                      }
                    } catch (_) {
                      // keep original
                    }
                  }
                  _translationCache.putIfAbsent(doc.id, () => {});
                  _translationCache[doc.id]![targetLang] = display;
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
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Text(
          widget.groupName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isPinned
                  ? [
                      const BoxShadow(
                        color: Color(0xFFFF6B6B),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                      const BoxShadow(
                        color: Color(0xFF0D0D0D),
                        offset: Offset(4, 4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                      const BoxShadow(
                        color: Color(0xFF2F2F2F),
                        offset: Offset(-4, -4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
            ),
            child: IconButton(
              tooltip: _isPinned ? 'Unpin Group' : 'Pin Group',
              icon: Icon(
                Icons.push_pin,
                color: _isPinned ? const Color(0xFFFF6B6B) : Colors.white70,
              ),
              onPressed: _togglePin,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF0D0D0D),
                  offset: Offset(4, 4),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Color(0xFF2F2F2F),
                  offset: Offset(-4, -4),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: preferredLang,
                icon: const Icon(Icons.translate, color: Colors.white70),
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => preferredLang = val);
                  _savePreferredLang(val);
                },
                items: const [
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(
                      'English',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'si',
                    child: Text(
                      'Sinhala',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ta',
                    child: Text('Tamil', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'fr',
                    child: Text(
                      'French',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'es',
                    child: Text(
                      'Spanish',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'de',
                    child: Text(
                      'German',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'hi',
                    child: Text('Hindi', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'zh-CN',
                    child: Text(
                      'Chinese',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ja',
                    child: Text(
                      'Japanese',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ar',
                    child: Text(
                      'Arabic',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ru',
                    child: Text(
                      'Russian',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'pt',
                    child: Text(
                      'Portuguese',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'it',
                    child: Text(
                      'Italian',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'tr',
                    child: Text(
                      'Turkish',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ur',
                    child: Text('Urdu', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'bn',
                    child: Text(
                      'Bengali',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ko',
                    child: Text(
                      'Korean',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'vi',
                    child: Text(
                      'Vietnamese',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'id',
                    child: Text(
                      'Indonesian',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'th',
                    child: Text('Thai', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'nl',
                    child: Text('Dutch', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'el',
                    child: Text('Greek', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'sv',
                    child: Text(
                      'Swedish',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'cs',
                    child: Text('Czech', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: 'ro',
                    child: Text(
                      'Romanian',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'hu',
                    child: Text(
                      'Hungarian',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'sk',
                    child: Text(
                      'Slovak',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'pl',
                    child: Text(
                      'Polish',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'uk',
                    child: Text(
                      'Ukrainian',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF0D0D0D),
                  offset: Offset(4, 4),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Color(0xFF2F2F2F),
                  offset: Offset(-4, -4),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.group, color: Colors.white70),
              tooltip: 'Members',
              onPressed: _showMembersBottomSheet,
            ),
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
                    child: Text(
                      'No messages yet. Say hello!',
                      style: TextStyle(color: Colors.white54),
                    ),
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
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                              gradient: isMe
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6B6B),
                                        Color(0xFFEE5A5A),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              boxShadow: isMe
                                  ? [
                                      const BoxShadow(
                                        color: Color(0xFFFF6B6B),
                                        blurRadius: 12,
                                        spreadRadius: -2,
                                      ),
                                      const BoxShadow(
                                        color: Color(0xFF0D0D0D),
                                        offset: Offset(6, 6),
                                        blurRadius: 12,
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : [
                                      const BoxShadow(
                                        color: Color(0xFF0D0D0D),
                                        offset: Offset(6, 6),
                                        blurRadius: 12,
                                        spreadRadius: 0,
                                      ),
                                      const BoxShadow(
                                        color: Color(0xFF2F2F2F),
                                        offset: Offset(-6, -6),
                                        blurRadius: 12,
                                        spreadRadius: 0,
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF1E1E1E),
                                        boxShadow: isMe
                                            ? [
                                                const BoxShadow(
                                                  color: Color(0x33FFFFFF),
                                                  offset: Offset(-2, -2),
                                                  blurRadius: 4,
                                                  spreadRadius: 0,
                                                ),
                                                const BoxShadow(
                                                  color: Color(0x66000000),
                                                  offset: Offset(2, 2),
                                                  blurRadius: 4,
                                                  spreadRadius: 0,
                                                ),
                                              ]
                                            : [
                                                const BoxShadow(
                                                  color: Color(0xFF0D0D0D),
                                                  offset: Offset(2, 2),
                                                  blurRadius: 4,
                                                  spreadRadius: 0,
                                                ),
                                                const BoxShadow(
                                                  color: Color(0xFF2F2F2F),
                                                  offset: Offset(-2, -2),
                                                  blurRadius: 4,
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTime(createdAt),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (isMe) ...[
                                  Text(
                                    (msg['text'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    (msg['displayText'] ?? msg['text'] ?? '')
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (msg['text'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white38,
                                      fontStyle: FontStyle.italic,
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
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF0D0D0D),
                    offset: Offset(0, -4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0xFF2A2A2A),
                    offset: Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF0D0D0D),
                            offset: Offset(4, 4),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Color(0xFF2F2F2F),
                            offset: Offset(-4, -4),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(
                            color: Colors.white38,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFEE5A5A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        const BoxShadow(
                          color: Color(0xFFFF6B6B),
                          blurRadius: 16,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(4, 4),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _sendMessage,
                        customBorder: const CircleBorder(),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
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
