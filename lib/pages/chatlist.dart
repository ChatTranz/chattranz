import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friend_requests_page.dart'; // Make sure this file exists

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please log in.'));
    }

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
              _showSearchDialog();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'add_friend') _showAddFriendDialog();
              if (value == 'friend_requests') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FriendRequestsPage()),
                );
              }
              if (value == 'create_group') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group creation coming soon')),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'add_friend', child: Text('Add Friend')),
              PopupMenuItem(value: 'friend_requests', child: Text('Friend Requests')),
              PopupMenuItem(value: 'create_group', child: Text('Create Group')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('friends')
            .doc(currentUser.uid)
            .collection('userFriends')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name']?.toLowerCase() ?? '';
            final email = data['email']?.toLowerCase() ?? '';
            return name.contains(_searchQuery.toLowerCase()) ||
                email.contains(_searchQuery.toLowerCase());
          }).toList();

          if (friends.isEmpty) {
            return const Center(
              child: Text(
                'No friends found.\nTry adding new friends!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index].data() as Map<String, dynamic>;
              final name = friend['name'] ?? 'Unknown';
              final email = friend['email'] ?? 'No email';

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFBBDEFB),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(name),
                subtitle: Text(email),
                onTap: () {
                  // TODO: Open chat page with this friend
                },
              );
            },
          );
        },
      ),
    );
  }

  // 🔍 Search dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Search Friends"),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Enter name or email",
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  // ➕ Add Friend Dialog (by email)
  void _showAddFriendDialog() {
    final TextEditingController emailController = TextEditingController();
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Friend"),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              hintText: "Enter friend's email",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;

                final userSnapshot = await _firestore
                    .collection('users')
                    .where('email', isEqualTo: email)
                    .get();

                if (userSnapshot.docs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User not found")),
                  );
                  return;
                }

                final friendData = userSnapshot.docs.first;
                final receiverId = friendData.id;

                // Prevent sending to self
                if (receiverId == currentUser.uid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("You cannot add yourself")),
                  );
                  return;
                }

                // Create friend request
                await _firestore.collection('friend_requests').add({
                  'senderId': currentUser.uid,
                  'receiverId': receiverId,
                  'status': 'pending',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Friend request sent")),
                );

                Navigator.pop(context);
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }
}
