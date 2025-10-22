import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  String selectedLanguage = "English";
  bool showAttachmentOptions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            // Top bar (Back, Title, Menu)
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
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Message",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  // Updated menu button with popup menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          // TODO: Navigate to view contact page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("View Contact tapped"),
                            ),
                          );
                          break;
                        case 'search':
                          // TODO: Implement search functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Search tapped")),
                          );
                          break;
                        case 'report':
                          // TODO: Handle report action
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Report tapped")),
                          );
                          break;
                        case 'block':
                          // TODO: Handle block action
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Block tapped")),
                          );
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.blue),
                            SizedBox(width: 10),
                            Text("View Contact"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'search',
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.blue),
                            SizedBox(width: 10),
                            Text("Search"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag, color: Colors.red),
                            SizedBox(width: 10),
                            Text("Report"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(Icons.block, color: Colors.red),
                            SizedBox(width: 10),
                            Text("Block"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // User info row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(
                      "https://i.pravatar.cc/150?img=3",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "David Wayne",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Online",
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: selectedLanguage,
                    items: ["English", "Sinhala", "Tamil"]
                        .map(
                          (lang) =>
                              DropdownMenuItem(value: lang, child: Text(lang)),
                        )
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

      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Close attachment box when tapping outside
          if (showAttachmentOptions) {
            setState(() {
              showAttachmentOptions = false;
            });
          }
        },
        child: Column(
          children: [
            // Chat messages
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildReceivedMessage("Hi! How are you?", "10:00"),
                  _buildSentMessage("I’m good, thanks! You?", "10:01"),
                ],
              ),
            ),

            // Drop-up menu (no animation)
            if (showAttachmentOptions)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _iconButtonOption(Icons.camera_alt, "Camera", () {
                          // TODO: camera action
                        }),
                        _iconButtonOption(Icons.mic, "Voice", () {
                          // TODO: voice record action
                        }),
                        _iconButtonOption(Icons.contacts, "Contact", () {
                          // TODO: contact picker action
                        }),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _iconButtonOption(Icons.photo, "Gallery", () {
                          // TODO: gallery action
                        }),
                        _iconButtonOption(Icons.location_on, "Location", () {
                          // TODO: location picker action
                        }),
                        _iconButtonOption(
                          Icons.insert_drive_file,
                          "Document",
                          () {
                            // TODO: document picker action
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Bottom input row
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Plus button
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        size: 30,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        setState(() {
                          showAttachmentOptions = !showAttachmentOptions;
                        });
                      },
                    ),

                    // Text field
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey.shade300),
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

                    // Send button
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () {
                          // TODO: send message logic
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Message widgets
  Widget _buildSentMessage(String text, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedMessage(String text, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButtonOption(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blue[50],
          child: IconButton(
            icon: Icon(icon, color: Colors.blue, size: 26),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
