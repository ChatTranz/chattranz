import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Friend Requests"),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('friend_requests')
            .where('receiverId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(
              child: Text("No pending friend requests."),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final senderId = request['senderId'];

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(senderId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Loading..."));
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final senderName = userData['name'] ?? 'Unknown';
                  final senderEmail = userData['email'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFBBDEFB),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(senderName),
                      subtitle: Text(senderEmail),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await _acceptRequest(
                                  request.id, senderId, currentUser.uid);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text("Accept"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await _rejectRequest(request.id);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text("Reject"),
                          ),
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
    );
  }

  // ✅ Accept friend request
  Future<void> _acceptRequest(
      String requestId, String senderId, String receiverId) async {
    try {
      final senderSnapshot =
          await _firestore.collection('users').doc(senderId).get();
      final receiverSnapshot =
          await _firestore.collection('users').doc(receiverId).get();

      if (!senderSnapshot.exists || !receiverSnapshot.exists) return;

      final senderData = senderSnapshot.data()!;
      final receiverData = receiverSnapshot.data()!;

      // Update request status
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add each other as friends
      await _firestore
          .collection('friends')
          .doc(senderId)
          .collection('userFriends')
          .doc(receiverId)
          .set({
        'name': receiverData['name'],
        'email': receiverData['email'],
        'addedAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('friends')
          .doc(receiverId)
          .collection('userFriends')
          .doc(senderId)
          .set({
        'name': senderData['name'],
        'email': senderData['email'],
        'addedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend request accepted ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ❌ Reject friend request
  Future<void> _rejectRequest(String requestId) async {
    try {
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend request rejected ❌")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}
