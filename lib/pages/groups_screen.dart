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
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Member',
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
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Email or user ID',
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
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.white54),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4757),
            ),
            onPressed: () async {
              // TODO: Look up user by email and add their uid to members
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite sent / member added')),
              );
            },
            child: const Text(
              'Add',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Exit Group',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to exit this group?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.white54),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4757),
            ),
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
            child: const Text(
              'Exit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, String groupId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Group',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will permanently delete the group for all members.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.white54),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4757),
            ),
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
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.03),
                      offset: const Offset(-3, -3),
                      blurRadius: 8,
                    ),
                    const BoxShadow(
                      color: Colors.black54,
                      offset: Offset(3, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
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
                            offset: const Offset(-2, -2),
                            blurRadius: 4,
                          ),
                          const BoxShadow(
                            color: Colors.black54,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        groupName.isNotEmpty ? groupName[0].toUpperCase() : 'G',
                        style: const TextStyle(
                          color: Color(0xFFFF4757),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${members.length} members',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Created: ${DateTime.fromMillisecondsSinceEpoch(createdAt.millisecondsSinceEpoch)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
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
            title: const Text(
              'Groups',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: StreamBuilder<Set<String>>(
        // first listen to pinned groups
        stream: GroupService.pinnedGroupsStream(),
        builder: (context, pinnedSnap) {
          final pinned = pinnedSnap.data ?? const <String>{};
          return StreamBuilder<QuerySnapshot>(
            stream: groupsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF4757),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                          Icons.group_outlined,
                          size: 80,
                          color: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No groups yet',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create one!',
                        style: TextStyle(color: Colors.white38, fontSize: 16),
                      ),
                    ],
                  ),
                );
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

                  return Container(
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
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'G',
                                  style: const TextStyle(
                                    color: Color(0xFFFF4757),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (isPinned) ...[
                                          const Icon(
                                            Icons.push_pin,
                                            size: 16,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${members.length} members',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                color: const Color(0xFF2A2A2A),
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.05),
                                        offset: const Offset(-2, -2),
                                        blurRadius: 4,
                                      ),
                                      const BoxShadow(
                                        color: Colors.black54,
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ),
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'info':
                                      _showGroupInfoBottomSheet(
                                        context,
                                        groupName: name,
                                        members: members,
                                        createdAt:
                                            data['createdAt'] as Timestamp?,
                                      );
                                      break;
                                    case 'add':
                                      _showAddMemberDialog(context, d.id);
                                      break;
                                    case 'pin':
                                      if (isPinned) {
                                        await GroupService.unpinGroup(d.id);
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Group unpinned'),
                                            ),
                                          );
                                        }
                                      } else {
                                        await GroupService.pinGroup(d.id);
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
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
                                  PopupMenuItem(
                                    value: 'info',
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.info_outline,
                                          color: Color(0xFFFF4757),
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Group Info',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'add',
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.person_add,
                                          color: Color(0xFFFF4757),
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Add Members',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'pin',
                                    child: Row(
                                      children: [
                                        Icon(
                                          isPinned
                                              ? Icons.push_pin_outlined
                                              : Icons.push_pin,
                                          color: const Color(0xFFFF4757),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          isPinned
                                              ? 'Unpin Group'
                                              : 'Pin Group',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'exit',
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.exit_to_app,
                                          color: Color(0xFFFF4757),
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Exit Group',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFFFF4757),
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Delete Group',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
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
            const BoxShadow(
              color: Colors.black54,
              offset: Offset(0, 8),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateGroupPage()),
              );
              if (mounted) setState(() {});
            },
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.group_add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Create Group',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
