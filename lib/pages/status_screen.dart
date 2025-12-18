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
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Always show My Status section at top
          _buildMyStatusSection(currentUser.uid),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recent Updates',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('friends')
                  .doc(currentUser.uid)
                  .collection('userFriends')
                  .snapshots(),
              builder: (context, friendsSnapshot) {
                if (friendsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Get list of friend IDs
                final friendIds =
                    friendsSnapshot.data?.docs.map((doc) => doc.id).toSet() ??
                    <String>{};

                if (friendIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 100,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Add friends to see their status updates',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('statuses')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final statuses = snapshot.data?.docs ?? [];

                    // Filter: only friends' statuses, not expired, not own
                    final now = DateTime.now();
                    final filteredStatuses = statuses.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final userId = data['userId'] as String? ?? '';
                      final timestamp = data['timestamp'] as Timestamp?;

                      // Must be a friend's status
                      if (!friendIds.contains(userId)) return false;
                      // Must have valid timestamp
                      if (timestamp == null) return false;
                      // Must be within 24 hours
                      final statusTime = timestamp.toDate();
                      return now.difference(statusTime).inHours < 24;
                    }).toList();

                    if (filteredStatuses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.circle_outlined,
                              size: 100,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No recent statuses from friends',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Group statuses by user
                    final Map<String, List<QueryDocumentSnapshot>>
                    groupedByUser = {};
                    for (var doc in filteredStatuses) {
                      final data = doc.data() as Map<String, dynamic>;
                      final userId = data['userId'] as String? ?? '';
                      if (!groupedByUser.containsKey(userId)) {
                        groupedByUser[userId] = [];
                      }
                      groupedByUser[userId]!.add(doc);
                    }

                    // Sort each user's statuses by timestamp desc
                    groupedByUser.forEach((userId, statusList) {
                      statusList.sort((a, b) {
                        final ta =
                            (a.data() as Map<String, dynamic>)['timestamp']
                                as Timestamp?;
                        final tb =
                            (b.data() as Map<String, dynamic>)['timestamp']
                                as Timestamp?;
                        final ma = ta?.millisecondsSinceEpoch ?? 0;
                        final mb = tb?.millisecondsSinceEpoch ?? 0;
                        return mb.compareTo(ma);
                      });
                    });

                    final userIds = groupedByUser.keys.toList();

                    return ListView.builder(
                      itemCount: userIds.length,
                      itemBuilder: (context, index) {
                        final userId = userIds[index];
                        final userStatuses = groupedByUser[userId]!;
                        final firstStatus =
                            userStatuses.first.data() as Map<String, dynamic>;
                        final userName =
                            firstStatus['userName'] as String? ?? 'Unknown';
                        final photoUrl = firstStatus['photoUrl'] as String?;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF4757),
                                          Color(0xFFFF6B7A),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.transparent,
                                      backgroundImage: photoUrl != null
                                          ? NetworkImage(photoUrl)
                                          : null,
                                      child: photoUrl == null
                                          ? Text(
                                              userName.isNotEmpty
                                                  ? userName[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 120,
                              padding: const EdgeInsets.only(left: 16),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: userStatuses.length,
                                itemBuilder: (context, statusIndex) {
                                  final statusDoc = userStatuses[statusIndex];
                                  final data =
                                      statusDoc.data() as Map<String, dynamic>;
                                  final statusText =
                                      data['statusText'] as String? ?? '';
                                  final timestamp =
                                      data['timestamp'] as Timestamp?;

                                  return GestureDetector(
                                    onTap: () => _showStatusDetail(
                                      userName,
                                      statusText,
                                      photoUrl,
                                      timestamp,
                                    ),
                                    child: Container(
                                      width: 80,
                                      margin: const EdgeInsets.only(right: 12),
                                      child: Column(
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
                                                backgroundColor:
                                                    Colors.grey[300],
                                                backgroundImage:
                                                    photoUrl != null
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
                              ),
                            ),
                            const Divider(height: 1),
                          ],
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4757).withOpacity(0.5),
              offset: const Offset(0, 4),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () => _showAddStatusDialog(null, null),
          child: const Icon(Icons.add, color: Colors.white),
        ),
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
                  color: Colors.white.withOpacity(0.7),
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
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
                title: const Text(
                  'My Status',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                subtitle: const Text(
                  'Tap to add status update',
                  style: TextStyle(color: Colors.white54),
                ),
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
                                          color: const Color(0xFFFF4757),
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
        backgroundColor: const Color(0xFF252525),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEditing ? 'Edit Status' : 'Add Status',
          style: const TextStyle(color: Colors.white),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.03),
                offset: const Offset(-4, -4),
                blurRadius: 8,
              ),
              const BoxShadow(
                color: Colors.black87,
                offset: Offset(4, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'What\'s on your mind?',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: const Color(0xFF252525),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFFF4757),
                  width: 2.0,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 3,
            maxLength: 200,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4757).withOpacity(0.5),
                  offset: const Offset(0, 4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
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
                      backgroundColor: const Color(0xFF252525),
                      content: Text(
                        isEditing
                            ? 'Status updated successfully'
                            : 'Status added successfully',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                isEditing ? 'Update' : 'Post',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusOptionsMenu(String statusId, String statusText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252525),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFFFF4757)),
              title: const Text(
                'Edit Status',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddStatusDialog(statusId, statusText);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Status',
                style: TextStyle(color: Colors.white),
              ),
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
        backgroundColor: const Color(0xFF252525),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Status',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete your status?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
              ),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                await _firestore.collection('statuses').doc(statusId).delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF252525),
                      content: Text(
                        'Status deleted successfully',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
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
