import 'package:flutter/material.dart';
import 'package:chattranz/pages/create_group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  Future<List<Map<String, dynamic>>> _fetchMembers(List<dynamic> ids) async {
    if (ids.isEmpty) return [];
    final cols = ids.map(
      (id) => FirebaseFirestore.instance
          .collection('users')
          .doc(id as String)
          .get(),
    );
    final docs = await Future.wait(cols);
    return docs
        .where((d) => d.exists)
        .map((d) => {'id': d.id, 'data': d.data()})
        .toList();
  }

  void _showGroupMembers(BuildContext context, List<dynamic> memberIds) async {
    final members = await _fetchMembers(memberIds);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 400,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final m = members[index];
                    final data = m['data'] as Map<String, dynamic>?;
                    final name =
                        (data?['displayName'] ??
                                data?['name'] ??
                                data?['email'] ??
                                'User')
                            .toString();
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text(data?['email'] ?? ''),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Groups'), centerTitle: true),
        body: const Center(child: Text('Please sign in to see groups')),
      );
    }

    // includeMetadataChanges helps surface local writes immediately.
    // Avoid server-side orderBy to prevent missing composite index errors.
    final groupsStream = FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: uid)
        .snapshots(includeMetadataChanges: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Groups'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: groupsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No groups yet. Create one!'));
          }

          // Sort client-side by createdAt desc to avoid requiring a composite index
          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final ad = a.data() as Map<String, dynamic>;
              final bd = b.data() as Map<String, dynamic>;
              final at =
                  (ad['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final bt =
                  (bd['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return bt.compareTo(at);
            });
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>;
              final name = (data['name'] ?? 'Group').toString();
              final members = List<dynamic>.from(data['members'] ?? []);

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () => _showGroupMembers(context, members),
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'G'),
                  ),
                  title: Text(name),
                  subtitle: Text('${members.length} members'),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showGroupMembers(context, members),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Force a rebuild when returning so UI refreshes if needed
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateGroupPage()));
          if (mounted) setState(() {});
        },
        label: const Text('Create Group'),
        icon: const Icon(Icons.group_add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
