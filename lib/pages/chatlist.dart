import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friend_requests_page.dart';
import 'conversation.dart';
import 'profile_screen.dart';
import 'create_group.dart';

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
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.03),
                offset: const Offset(0, -2),
                blurRadius: 8,
              ),
              const BoxShadow(
                color: Colors.black54,
                offset: Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E1E1E),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      offset: const Offset(-2, -2),
                      blurRadius: 6,
                    ),
                    const BoxShadow(
                      color: Colors.black54,
                      offset: Offset(2, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Image.asset(
                    'assets/loadingLogo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            title: const Text(
              'ChatTranz',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              _buildNeumorphicIconButton(
                icon: Icons.search,
                onPressed: () {
                  _showSearchDialog();
                },
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        offset: const Offset(-2, -2),
                        blurRadius: 6,
                      ),
                      const BoxShadow(
                        color: Colors.black54,
                        offset: Offset(2, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
                color: const Color(0xFF2A2A2A),
                onSelected: (value) {
                  if (value == 'add_friend') _showAddFriendDialog();
                  if (value == 'friend_requests') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FriendRequestsPage(),
                      ),
                    );
                  }
                  if (value == 'create_group') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateGroupPage(),
                      ),
                    );
                  }
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  }
                },
                itemBuilder: (context) => [
                  _buildPopupMenuItem(
                    'add_friend',
                    'Add Friend',
                    Icons.person_add,
                  ),
                  _buildPopupMenuItem(
                    'friend_requests',
                    'Friend Requests',
                    Icons.mail,
                  ),
                  _buildPopupMenuItem(
                    'create_group',
                    'Create Group',
                    Icons.group_add,
                  ),
                  _buildPopupMenuItem(
                    'profile',
                    'Profile',
                    Icons.account_circle,
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.03),
                          offset: const Offset(-6, -6),
                          blurRadius: 12,
                        ),
                        const BoxShadow(
                          color: Colors.black54,
                          offset: Offset(6, 6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.people_outline,
                      size: 80,
                      color: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No friends found',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try adding new friends!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white38),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index].data() as Map<String, dynamic>;
              final name = friend['name'] ?? 'Unknown';
              final email = friend['email'] ?? 'No email';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        offset: const Offset(-4, -4),
                        blurRadius: 10,
                      ),
                      const BoxShadow(
                        color: Colors.black54,
                        offset: Offset(4, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              friendId: friend['friendId'] ?? friends[index].id,
                              friendName: name,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.05),
                                    offset: const Offset(-3, -3),
                                    blurRadius: 6,
                                  ),
                                  const BoxShadow(
                                    color: Colors.black54,
                                    offset: Offset(3, 3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFFFF4757),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white38,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Search Friends",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.03),
                  offset: const Offset(-3, -3),
                  blurRadius: 6,
                ),
                const BoxShadow(
                  color: Colors.black87,
                  offset: Offset(3, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter name or email",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF252525),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF4757),
              ),
              child: const Text(
                "Close",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
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
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Add Friend",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.03),
                  offset: const Offset(-3, -3),
                  blurRadius: 6,
                ),
                const BoxShadow(
                  color: Colors.black87,
                  offset: Offset(3, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter friend's email",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF252525),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: const Text(
                "Cancel",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF4757),
              ),
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
              child: const Text(
                "Send",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Neumorphic Icon Button
  Widget _buildNeumorphicIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            offset: const Offset(-2, -2),
            blurRadius: 6,
          ),
          const BoxShadow(
            color: Colors.black54,
            offset: Offset(2, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
        ),
      ),
    );
  }

  // Popup Menu Item with styling
  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    String text,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF4757), size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
