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
              // Handle search action
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Handle more options
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildChatItem(
            name: 'You',
            message: 'Thanks a bunch! Have a great day! 😀',
            time: '10:25',
            unreadCount: 5,
            avatarColor: Colors.brown,
          ),
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
          _buildChatItem(
            name: 'Angela Kelly',
            message: 'Appreciate it! See you soon! 🚀',
            time: '10:45 08/05',
            unreadCount: 1,
            avatarColor: Colors.brown,
          ),
          _buildChatItem(
            name: 'Jean Dare',
            message: 'Hooray! 🎉',
            time: '20:10 05/05',
            unreadCount: 0,
            avatarColor: Colors.brown,
          ),
          _buildChatItem(
            name: 'Dennis Borer',
            message: 'Your order has been successfully delivered',
            time: '17:02 05/05',
            unreadCount: 0,
            avatarColor: Colors.grey,
          ),
          _buildChatItem(
            name: 'Cayla Rath',
            message: 'See you soon!',
            time: '11:20 05/05',
            unreadCount: 0,
            avatarColor: Colors.brown,
          ),
          _buildChatItem(
            name: 'Erin Turcotte',
            message: 'I\'m ready to drop off my delivery. 👍',
            time: '19:35 02/05',
            unreadCount: 0,
            avatarColor: Colors.brown,
          ),
          _buildChatItem(
            name: 'Rodolfo Walter',
            message: 'Appreciate it! Hope you enjoy it!',
            time: '07:55 01/05',
            unreadCount: 0,
            avatarColor: Colors.grey,
          ),
        ],
      ),
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
