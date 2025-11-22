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
                    return false; // show only when searching
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
                // When not searching show call log
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _callService.myCallsStream(),
                  builder: (context, callSnap) {
                    if (callSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final callDocs = callSnap.data?.docs ?? [];
                    if (callDocs.isEmpty) {
                      return const Center(child: Text('No calls yet'));
                    }
                    final currentId = currentUser?.uid ?? '';
                    return ListView.builder(
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
                        return ListTile(
                          leading: Icon(
                            icon,
                            color: entry.isOutgoing
                                ? Colors.green
                                : Colors.blue,
                          ),
                          title: Text(entry.otherName),
                          subtitle: Text(entry.status),
                          onTap: () {
                            // Re-open existing call screen if still active
                            if (entry.status != 'ended') {
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
}

class CallLogEntry {
  final String id;
  final String otherName;
  final bool isOutgoing;
  final String status;

  CallLogEntry({
    required this.id,
    required this.otherName,
    required this.isOutgoing,
    required this.status,
  });

  factory CallLogEntry.fromDoc(
    String id,
    Map<String, dynamic> data,
    String currentUserId,
  ) {
    final callerId = data['callerId'] as String? ?? '';
    final isOutgoing = callerId == currentUserId;
    final otherName = isOutgoing
        ? (data['receiverName'] as String? ?? 'Unknown')
        : (data['callerName'] as String? ?? 'Unknown');
    return CallLogEntry(
      id: id,
      otherName: otherName,
      isOutgoing: isOutgoing,
      status: data['status'] as String? ?? 'calling',
    );
  }
}
