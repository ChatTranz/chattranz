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
      appBar: AppBar(
        title: const Text('Calls'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search user to call',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
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
                  return const Center(child: CircularProgressIndicator());
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
                  return const Center(child: Text('No users match search'));
                }
                if (_searchQuery.isNotEmpty) {
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final data = filtered[index].data();
                      final avatar = data['profileImage'] as String?;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: avatar != null
                              ? NetworkImage(avatar)
                              : null,
                          child: avatar == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text((data['name'] ?? 'Unknown') as String),
                        trailing: IconButton(
                          icon: const Icon(Icons.call),
                          onPressed: () => _startCall(data),
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
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load call log. ${callSnap.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'If Firestore shows an index error, create composite index: calls(participants arrayContains, startedAt desc).',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (callSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final callDocs = callSnap.data?.docs ?? [];
                    if (callDocs.isEmpty) {
                      return const Center(child: Text('No calls yet'));
                    }
                    final currentId = currentUser?.uid ?? '';
                    return ListView.separated(
                      itemCount: callDocs.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
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
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: entry.isOutgoing
                                ? Colors.green.withOpacity(.15)
                                : Colors.blue.withOpacity(.15),
                            child: Icon(
                              icon,
                              color: entry.isOutgoing
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ),
                          title: Text(entry.otherName),
                          subtitle: Text(_statusLabel(entry.status)),
                          trailing: Text(
                            _timeLabel(doc.data()['startedAt'] as Timestamp?),
                          ),
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
