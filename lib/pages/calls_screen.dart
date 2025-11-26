import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'calling.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final _searchController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _callService = CallService();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _usersStream() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  Future<void> _startCall(Map<String, dynamic> userData) async {
    try {
      final callId = await _callService.startCall(
        receiverId: userData['uid'] as String,
        receiverName: (userData['name'] ?? 'Unknown') as String,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallingScreen(
            callId: callId,
            friendId: userData['uid'] as String,
            friendName: (userData['name'] ?? 'Unknown') as String,
            friendPhotoUrl: userData['profileImage'] as String?,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start call: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
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
            title: const Text(
              'Calls',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(25),
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
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search user to call',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white38,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF252525),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF4757),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _usersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF4757),
                      ),
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((d) {
                  if (d.data()['uid'] == currentUser?.uid)
                    return false; // exclude self
                  if (_searchQuery.isEmpty)
                    return false; // only show results when searching
                  final name = (d.data()['name'] ?? '') as String;
                  return name.toLowerCase().contains(_searchQuery);
                }).toList();
                if (_searchQuery.isNotEmpty && filtered.isEmpty) {
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
                            Icons.search_off,
                            size: 60,
                            color: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No users match search',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (_searchQuery.isNotEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final data = filtered[index].data();
                      final avatar = data['profileImage'] as String?;
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
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
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
                                  child: CircleAvatar(
                                    backgroundImage: avatar != null
                                        ? NetworkImage(avatar)
                                        : null,
                                    backgroundColor: const Color(0xFF252525),
                                    child: avatar == null
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.white38,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    (data['name'] ?? 'Unknown') as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4CAF50),
                                        Color(0xFF66BB6A),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF4CAF50,
                                        ).withOpacity(0.5),
                                        offset: const Offset(0, 4),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.call,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => _startCall(data),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _callService.myCallsStream(),
                  builder: (context, callSnap) {
                    if (callSnap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(30),
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
                                Icons.error_outline,
                                size: 48,
                                color: Color(0xFFFF4757),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Failed to load call log',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'If Firestore shows an index error, create composite index: calls(participants arrayContains, startedAt desc).',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (callSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF4757),
                          ),
                        ),
                      );
                    }
                    final callDocs = callSnap.data?.docs ?? [];
                    if (callDocs.isEmpty) {
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
                                Icons.call_outlined,
                                size: 80,
                                color: Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No calls yet',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Search for users to start calling',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final currentId = currentUser?.uid ?? '';
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: callDocs.length,
                      itemBuilder: (context, index) {
                        final doc = callDocs[index];
                        final entry = CallLogEntry.fromDoc(
                          doc.id,
                          doc.data(),
                          currentId,
                        );
                        final icon = entry.isOutgoing
                            ? Icons.call_made
                            : Icons.call_received;
                        final iconColor = entry.isOutgoing
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF2196F3);

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
                                  if (entry.status != 'ended' &&
                                      entry.status != 'declined') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CallingScreen(
                                          callId: entry.id,
                                          friendId: '',
                                          friendName: entry.otherName,
                                        ),
                                      ),
                                    );
                                  }
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
                                              color: Colors.white.withOpacity(
                                                0.05,
                                              ),
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
                                        child: Icon(
                                          icon,
                                          color: iconColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.otherName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _statusLabel(entry.status),
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _timeLabel(
                                          doc.data()['startedAt'] as Timestamp?,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'calling':
        return 'Calling';
      case 'ringing':
        return 'Ringing';
      case 'answered':
        return 'In Call';
      case 'ended':
        return 'Ended';
      case 'declined':
        return 'Declined';
      default:
        return status;
    }
  }

  String _timeLabel(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day}';
  }
}
