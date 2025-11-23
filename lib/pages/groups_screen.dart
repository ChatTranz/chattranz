import 'package:flutter/material.dart';
import 'package:chattranz/pages/create_group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_chat_page.dart';
import 'package:chattranz/services/group_service.dart';
// Group info is displayed inline via a bottom sheet; no extra page import.

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  void _showAddMemberDialog(BuildContext context, String groupId) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Email or user ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Look up user by email and add their uid to members
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite sent / member added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog(BuildContext context, String groupId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Group'),
        content: const Text('Are you sure you want to exit this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              if (uid != null) {
                try {
                  await FirebaseFirestore.instance
                      .collection('groups')
                      .doc(groupId)
                      .update({
                        'members': FieldValue.arrayRemove([uid]),
                      });
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Exited group')));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Failed to exit: $e')));
                }
              }
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, String groupId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'This will permanently delete the group for all members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupId)
                    .delete();
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Group deleted')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showGroupInfoBottomSheet(
    BuildContext context, {
    required String groupName,
    required List<dynamic> members,
    Timestamp? createdAt,
  }) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Group Info',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(
                    groupName.isNotEmpty ? groupName[0].toUpperCase() : 'G',
                  ),
                ),
                title: Text(groupName),
                subtitle: Text('${members.length} members'),
              ),
              if (createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Created: ${DateTime.fromMillisecondsSinceEpoch(createdAt.millisecondsSinceEpoch)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // (Old member bottom sheet kept for reference; now group tap opens chat.)

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
      body: StreamBuilder<Set<String>>(
        // first listen to pinned groups
        stream: GroupService.pinnedGroupsStream(),
        builder: (context, pinnedSnap) {
          final pinned = pinnedSnap.data ?? const <String>{};
          return StreamBuilder<QuerySnapshot>(
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
              final allDocs = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final ad = a.data() as Map<String, dynamic>;
                  final bd = b.data() as Map<String, dynamic>;
                  final at =
                      (ad['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                      0;
                  final bt =
                      (bd['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                      0;
                  return bt.compareTo(at);
                });

              // Partition into pinned and unpinned
              final pinnedDocs = <QueryDocumentSnapshot>[];
              final unpinnedDocs = <QueryDocumentSnapshot>[];
              for (final doc in allDocs) {
                if (pinned.contains(doc.id)) {
                  pinnedDocs.add(doc);
                } else {
                  unpinnedDocs.add(doc);
                }
              }
              final ordered = [...pinnedDocs, ...unpinnedDocs];

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: ordered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final d = ordered[index];
                  final data = d.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? 'Group').toString();
                  final members = List<dynamic>.from(data['members'] ?? []);
                  final isPinned = pinned.contains(d.id);

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupChatPage(
                            groupId: d.id,
                            groupName: name,
                            memberIds: members,
                          ),
                        ),
                      ),
                      leading: CircleAvatar(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'G',
                        ),
                      ),
                      title: Row(
                        children: [
                          if (isPinned) ...[
                            const Icon(
                              Icons.push_pin,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(child: Text(name)),
                        ],
                      ),
                      subtitle: Text('${members.length} members'),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          switch (value) {
                            case 'info':
                              _showGroupInfoBottomSheet(
                                context,
                                groupName: name,
                                members: members,
                                createdAt: data['createdAt'] as Timestamp?,
                              );
                              break;
                            case 'add':
                              _showAddMemberDialog(context, d.id);
                              break;
                            case 'pin':
                              if (isPinned) {
                                await GroupService.unpinGroup(d.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Group unpinned'),
                                    ),
                                  );
                                }
                              } else {
                                await GroupService.pinGroup(d.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Group pinned'),
                                    ),
                                  );
                                }
                              }
                              break;
                            case 'exit':
                              _showLeaveGroupDialog(context, d.id);
                              break;
                            case 'delete':
                              _confirmDeleteGroup(context, d.id);
                              break;
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'info',
                            child: Text('Group Info'),
                          ),
                          const PopupMenuItem(
                            value: 'add',
                            child: Text('Add Members'),
                          ),
                          PopupMenuItem(
                            value: 'pin',
                            child: Text(isPinned ? 'Unpin Group' : 'Pin Group'),
                          ),
                          const PopupMenuItem(
                            value: 'exit',
                            child: Text('Exit Group'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Group'),
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
