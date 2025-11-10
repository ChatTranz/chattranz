import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class ChatPage extends StatefulWidget {
  final String friendId;
  final String friendName;

  const ChatPage({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool showAttachmentOptions = false;
  String selectedLanguage = "English";
  late String chatId;

  @override
  void initState() {
    super.initState();
    final currentUser = _auth.currentUser!;
    chatId = getChatId(currentUser.uid, widget.friendId);
  }

  String getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode
        ? '$user1-$user2'
        : '$user2-$user1';
  }

  // 🔹 Language Mapping for ML Kit
  TranslateLanguage _mapLanguage(String lang) {
    switch (lang) {
      case "Sinhala":
        // Fallback: Sinhala is not supported by on-device translation
        return TranslateLanguage.english;
      case "Tamil":
        return TranslateLanguage.tamil;
      default:
        return TranslateLanguage.english;
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final currentUser = _auth.currentUser!;
    final timestamp = FieldValue.serverTimestamp();

    // 🔹 Translate message
    final sourceLang = TranslateLanguage.english;
    final targetLang = _mapLanguage(selectedLanguage);
    final translator = OnDeviceTranslator(
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
    );

    String translatedText = text;
    try {
      translatedText = await translator.translateText(text);
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            // 🔹 Row 1: Back, Message title, menu
            Padding(
              padding: const EdgeInsets.only(
                  left: 8, right: 8, top: 12, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Message",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
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
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage:
                        NetworkImage("https://i.pravatar.cc/150?img=3"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.friendName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Text("Online",
                            style:
                                TextStyle(color: Colors.green, fontSize: 12)),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: selectedLanguage,
                    items: ["English", "Sinhala", "Tamil"]
                        .map((lang) =>
                            DropdownMenuItem(value: lang, child: Text(lang)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLanguage = value!;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.blue),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 🔹 Chat body
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg =
                        messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUser.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isMe
                                  ? Colors.blueAccent
                                  : Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['translatedText'] ?? msg['text'],
                              style: TextStyle(
                                  color:
                                      isMe ? Colors.white : Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['text'],
                              style: TextStyle(
                                color:
                                    isMe ? Colors.white70 : Colors.grey,
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
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        showAttachmentOptions = !showAttachmentOptions;
                      });
                    },
                  ),
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border:
                            Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Type a message...",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () =>
                          sendMessage(_messageController.text),
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
