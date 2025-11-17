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
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select members',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(ctx).pop(selected.toList()),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
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
                          return CheckboxListTile(
                            value: checked,
                            title: Text(name),
                            onChanged: (v) {
                              setModalState(() {
                                if (v == true)
                                  selected.add(id);
                                else
                                  selected.remove(id);
                              });
                            },
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
        'createdAt': FieldValue.serverTimestamp(),
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
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // AppBar-like header
          Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A84FF), Color(0xFF1E90FF)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            padding: const EdgeInsets.only(top: 36, left: 8, right: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Create Group',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Name Group',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter Name Group',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                const Text('Members', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),

                GestureDetector(
                  onTap: _pickMembers,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: Color(0xFF0A84FF)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedMembers.isEmpty
                                ? 'Add members to group'
                                : '${_selectedMembers.length} members selected',
                            style: const TextStyle(color: Color(0xFF0A84FF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E90FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: _creating ? null : _createGroup,
                child: _creating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Group',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
