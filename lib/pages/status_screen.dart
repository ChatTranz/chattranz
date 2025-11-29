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
      body: Column(
        children: [
          // Always show My Status section at top
          _buildMyStatusSection(currentUser.uid),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('statuses')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // Delete expired statuses
                _deleteExpiredStatuses();

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final statuses = snapshot.data?.docs ?? [];
                if (statuses.isEmpty) {
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
                          'No status updates from friends yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter out expired statuses and own statuses
                final now = DateTime.now();
                final filteredStatuses = statuses.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final userId = data['userId'] as String? ?? '';
                  final timestamp = data['timestamp'] as Timestamp?;
                  if (userId == currentUser.uid) return false;
                  if (timestamp == null) return false;
                  final statusTime = timestamp.toDate();
                  return now.difference(statusTime).inHours < 24;
                }).toList();

                if (filteredStatuses.isEmpty) {
                  return Center(
                    child: Text(
                      'No recent statuses from friends',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredStatuses.length,
                  itemBuilder: (context, index) {
                    final statusDoc = filteredStatuses[index];
                    final data = statusDoc.data() as Map<String, dynamic>;
                    final userName = data['userName'] as String? ?? 'Unknown';
                    final statusText = data['statusText'] as String? ?? '';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final photoUrl = data['photoUrl'] as String?;

                    return ListTile(
                      leading: CircleAvatar(
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
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            )
                          : null,
                      onTap: () {
                        _showStatusDetail(
                          userName,
                          statusText,
                          photoUrl,
                          timestamp,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00BCD4),
        onPressed: () => _showAddStatusDialog(null, null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMyStatusSection(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('statuses')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Delete expired statuses in background
        _deleteExpiredStatuses();

        final allDocs = snapshot.data?.docs ?? [];

        // Filter to last 24h and sort by timestamp desc
        final now = DateTime.now();
        final myStatuses =
            allDocs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              final ts = data['timestamp'] as Timestamp?;
              if (ts == null) return false;
              return now.difference(ts.toDate()).inHours < 24;
            }).toList()..sort((a, b) {
              final ta =
                  (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              final tb =
                  (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              final ma = ta?.millisecondsSinceEpoch ?? 0;
              final mb = tb?.millisecondsSinceEpoch ?? 0;
              return mb.compareTo(ma);
            });

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
            if (myStatuses.isEmpty)
              ListTile(
                leading: StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('users').doc(uid).snapshots(),
                  builder: (context, userSnapshot) {
                    final userData =
                        userSnapshot.data?.data() as Map<String, dynamic>?;
                    final photoUrl = userData?['photoUrl'] as String?;
                    return CircleAvatar(
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
                title: const Text(
                  'My Status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Tap to add status update'),
                onTap: () => _showAddStatusDialog(null, null),
              )
            else
              Container(
                height: 120,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('users').doc(uid).snapshots(),
                  builder: (context, userSnapshot) {
                    final userData =
                        userSnapshot.data?.data() as Map<String, dynamic>?;
                    final photoUrl = userData?['photoUrl'] as String?;

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: myStatuses.length,
                      itemBuilder: (context, index) {
                        final statusDoc = myStatuses[index];
                        final data = statusDoc.data() as Map<String, dynamic>;
                        final statusText = data['statusText'] as String? ?? '';
                        final timestamp = data['timestamp'] as Timestamp?;

                        return GestureDetector(
                          onTap: () => _showMyStatusDetail(
                            statusDoc.id,
                            statusText,
                            timestamp,
                          ),
                          onLongPress: () =>
                              _showStatusOptionsMenu(statusDoc.id, statusText),
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF00BCD4),
                                          width: 3,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: CircleAvatar(
                                          backgroundColor: Colors.grey[300],
                                          backgroundImage: photoUrl != null
                                              ? NetworkImage(photoUrl)
                                              : null,
                                          child: photoUrl == null
                                              ? const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: InkWell(
                                        onTap: () => _showStatusOptionsMenu(
                                          statusDoc.id,
                                          statusText,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            Icons.more_vert,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timestamp != null
                                      ? _formatTimestamp(timestamp)
                                      : '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
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
          ],
        );
      },
    );
  }

  // Delete statuses older than 24 hours
  Future<void> _deleteExpiredStatuses() async {
    final now = DateTime.now();
    final cutoff = Timestamp.fromDate(now.subtract(const Duration(hours: 24)));

    try {
      final expiredStatuses = await _firestore
          .collection('statuses')
          .where('timestamp', isLessThan: cutoff)
          .get();

      for (var doc in expiredStatuses.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      // Silently fail - will try again on next load
    }
  }

  void _showAddStatusDialog(String? existingStatusId, String? existingText) {
    final TextEditingController controller = TextEditingController(
      text: existingText,
    );
    final isEditing = existingStatusId != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Status' : 'Add Status'),
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

              if (isEditing) {
                // Update existing status
                await _firestore
                    .collection('statuses')
                    .doc(existingStatusId)
                    .update({
                      'statusText': text,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
              } else {
                // Add new status to Firestore (don't delete old ones)
                await _firestore.collection('statuses').add({
                  'userId': currentUser.uid,
                  'userName': userData?['name'] ?? 'Unknown',
                  'photoUrl': userData?['photoUrl'],
                  'statusText': text,
                  'timestamp': FieldValue.serverTimestamp(),
                });
              }

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'Status updated successfully'
                          : 'Status added successfully',
                    ),
                  ),
                );
              }
            },
            child: Text(
              isEditing ? 'Update' : 'Post',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusOptionsMenu(String statusId, String statusText) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF00BCD4)),
              title: const Text('Edit Status'),
              onTap: () {
                Navigator.pop(context);
                _showAddStatusDialog(statusId, statusText);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Status'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteStatus(statusId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStatus(String statusId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Status'),
        content: const Text('Are you sure you want to delete your status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _firestore.collection('statuses').doc(statusId).delete();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Status deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMyStatusDetail(
    String statusId,
    String statusText,
    Timestamp? timestamp,
  ) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
            final userName = userData?['name'] as String? ?? 'You';
            final photoUrl = userData?['photoUrl'] as String?;

            return Container(
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
            );
          },
        ),
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
