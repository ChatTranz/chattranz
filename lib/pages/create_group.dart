import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<Map<String, dynamic>> _selectedMembers = [];
  bool _creating = false;

  Future<void> _pickMembers() async {
    // show a simple modal with users list and checkboxes
    final uid = _auth.currentUser!.uid;
    final snapshot = await _firestore.collection('users').limit(100).get();
    final users = snapshot.docs
        .where((d) => d.id != uid)
        .map((d) => {'id': d.id, 'data': d.data()})
        .toList();

    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        final selected = <String>{
          ..._selectedMembers.map((m) => m['id'] as String),
        };
        return StatefulBuilder(
          builder: (c, setModalState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.7,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select members',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFFF4757),
                            ),
                            onPressed: () =>
                                Navigator.of(ctx).pop(selected.toList()),
                            child: const Text(
                              'Done',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final u = users[index];
                          final id = u['id'] as String;
                          final data = u['data'] as Map<String, dynamic>;
                          final name =
                              (data['displayName'] ??
                                      data['name'] ??
                                      data['email'] ??
                                      'User')
                                  .toString();
                          final checked = selected.contains(id);
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.03),
                                  offset: const Offset(-2, -2),
                                  blurRadius: 6,
                                ),
                                const BoxShadow(
                                  color: Colors.black54,
                                  offset: Offset(2, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: CheckboxListTile(
                              value: checked,
                              title: Text(
                                name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              activeColor: const Color(0xFFFF4757),
                              checkColor: Colors.white,
                              tileColor: Colors.transparent,
                              onChanged: (v) {
                                setModalState(() {
                                  if (v == true)
                                    selected.add(id);
                                  else
                                    selected.remove(id);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      // refresh selected members list
      final docs = await Future.wait(
        picked.map((id) => _firestore.collection('users').doc(id).get()),
      );
      setState(() {
        _selectedMembers.clear();
        for (var d in docs) {
          if (d.exists) _selectedMembers.add({'id': d.id, 'data': d.data()});
        }
      });
    }
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one member')),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      final currentUser = _auth.currentUser!;
      final members = [
        currentUser.uid,
        ..._selectedMembers.map((m) => m['id'] as String),
      ];
      await _firestore.collection('groups').add({
        'name': name,
        'members': members,
        'creatorId': currentUser.uid,
        // Use a client-side timestamp so the UI sees the new group immediately
        'createdAt': Timestamp.now(),
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Group created')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create group: $e')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Column(
        children: [
          // Neumorphic header
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.05),
                  offset: const Offset(-6, -6),
                  blurRadius: 16,
                ),
                const BoxShadow(
                  color: Colors.black54,
                  offset: Offset(6, 6),
                  blurRadius: 16,
                ),
              ],
            ),
            padding: const EdgeInsets.only(top: 36, left: 8, right: 8),
            child: Row(
              children: [
                Container(
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
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Create Group',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Group Name',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
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
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter group name',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF252525),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF4757),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Members',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _pickMembers,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
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
                    child: Row(
                      children: [
                        Container(
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
                            Icons.person_add,
                            color: Color(0xFFFF4757),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _selectedMembers.isEmpty
                                ? 'Add members to group'
                                : '${_selectedMembers.length} members selected',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white38),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
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
                  onTap: _creating ? null : _createGroup,
                  borderRadius: BorderRadius.circular(25),
                  child: Center(
                    child: _creating
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Create Group',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
