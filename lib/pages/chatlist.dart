import 'package:flutter/material.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.chat_bubble,
              color: const Color(0xFF1976D2),
              size: 24,
            ),
          ),
        ),
        title: const Text(
          'ChatTranz',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search feature
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_friend') {
                _showActionDialog(context, 'Add Friend');
              } else if (value == 'create_group') {
                _showActionDialog(context, 'Create Group');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'add_friend',
                child: Text('Add Friend'),
              ),
              const PopupMenuItem(
                value: 'create_group',
                child: Text('Create Group'),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),

      // ✅ Chat list body
      body: ListView(
        children: [
          _buildChatItem(
            name: 'David Wayne',
            message: 'Thanks a bunch! Have a great day! 😀',
            time: 'Now',
            unreadCount: 6,
            avatarColor: Colors.brown,
          ),
          _buildChatItem(
            name: 'Edward Davidson',
            message: 'Great, thanks so much! 👍',
            time: '22:20 09/05',
            unreadCount: 12,
            avatarColor: Colors.blue,
          ),
          // ... add more dummy chats if needed
        ],
      ),

      // ✅ Floating Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00BCD4),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _showFABOptions(context);
        },
      ),
    );
  }

  // FAB menu options
  void _showFABOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.person_add, color: Color(0xFF1976D2)),
                title: const Text('Add Friend'),
                onTap: () {
                  Navigator.pop(context);
                  _showActionDialog(context, 'Add Friend');
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add, color: Color(0xFF1976D2)),
                title: const Text('Create Group'),
                onTap: () {
                  Navigator.pop(context);
                  _showActionDialog(context, 'Create Group');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Placeholder dialog
  void _showActionDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(title),
          content: Text('Feature "$title" will be added soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF1976D2)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatItem({
    required String name,
    required String message,
    required String time,
    required int unreadCount,
    required Color avatarColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: avatarColor.withOpacity(0.2),
          child: Icon(Icons.person, color: avatarColor, size: 28),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            Text(
              time,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          // Navigate to conversation page
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => ConversationPage(name: name),
          //   ),
          // );
        },
      ),
    );
  }
}
