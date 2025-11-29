import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        automaticallyImplyLeading: false,
        title: const Text(
          'Status',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('statuses')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No status updates yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final statuses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: statuses.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // My Status section
                return _buildMyStatusSection(currentUser.uid);
              }

              final statusDoc = statuses[index - 1];
              final data = statusDoc.data() as Map<String, dynamic>;
              final userId = data['userId'] as String? ?? '';
              final userName = data['userName'] as String? ?? 'Unknown';
              final statusText = data['statusText'] as String? ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              final photoUrl = data['photoUrl'] as String?;

              // Don't show own status in the list again
              if (userId == currentUser.uid) {
                return const SizedBox.shrink();
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF00BCD4),
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                title: Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: timestamp != null
                    ? Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      )
                    : null,
                onTap: () {
                  _showStatusDetail(userName, statusText, photoUrl, timestamp);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00BCD4),
        onPressed: _showAddStatusDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMyStatusSection(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('statuses')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final hasStatus = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        final statusDoc = hasStatus ? snapshot.data!.docs.first : null;
        final data = statusDoc?.data() as Map<String, dynamic>?;
        final statusText =
            data?['statusText'] as String? ?? 'Tap to add status';
        final timestamp = data?['timestamp'] as Timestamp?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'My Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ListTile(
              leading: Stack(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(currentUserId)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      final userData =
                          userSnapshot.data?.data() as Map<String, dynamic>?;
                      final photoUrl = userData?['photoUrl'] as String?;

                      return CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF00BCD4),
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              title: const Text(
                'My Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                hasStatus ? statusText : 'Tap to add status update',
                style: TextStyle(
                  color: hasStatus ? Colors.black87 : Colors.grey[600],
                ),
              ),
              trailing: timestamp != null
                  ? Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    )
                  : null,
              onTap: _showAddStatusDialog,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Recent Updates',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddStatusDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Status'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'What\'s on your mind?',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
            ),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Status cannot be empty')),
                );
                return;
              }

              final currentUser = _auth.currentUser;
              if (currentUser == null) return;

              // Get user details
              final userDoc = await _firestore
                  .collection('users')
                  .doc(currentUser.uid)
                  .get();
              final userData = userDoc.data();

              // Add status to Firestore
              await _firestore.collection('statuses').add({
                'userId': currentUser.uid,
                'userName': userData?['name'] ?? 'Unknown',
                'photoUrl': userData?['photoUrl'],
                'statusText': text,
                'timestamp': FieldValue.serverTimestamp(),
              });

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Status added successfully')),
                );
              }
            },
            child: const Text('Post', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStatusDetail(
    String userName,
    String statusText,
    String? photoUrl,
    Timestamp? timestamp,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF00BCD4),
                    backgroundImage: photoUrl != null
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null
                        ? Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (timestamp != null)
                          Text(
                            _formatTimestamp(timestamp),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                statusText,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
