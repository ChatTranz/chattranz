import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendsProfileScreen extends StatefulWidget {
  final String friendId;
  const FriendsProfileScreen({super.key, required this.friendId});

  @override
  State<FriendsProfileScreen> createState() => _FriendsProfileScreenState();
}

class _FriendsProfileScreenState extends State<FriendsProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _loading = true;
  String? _name;
  String? _bio;
  String? _profileImage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(widget.friendId)
          .get();
      final data = doc.data();
      if (data != null) {
        _name = (data['name'] ?? '') as String?;
        _bio = (data['bio'] ?? "Hey there! I'm using ChatTranz 😄") as String?;
        _profileImage = data['profileImage'] as String?;
      }
    } catch (e) {
      debugPrint('Friend profile load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text(_name == null || _name!.isEmpty ? 'Profile' : _name!),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: _resolveAvatar(_profileImage),
                      child: _resolveAvatar(_profileImage) == null
                          ? const Icon(
                              Icons.person,
                              size: 64,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _name ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _bio ?? "",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
    );
  }

  ImageProvider? _resolveAvatar(String? v) {
    if (v == null || v.isEmpty) return null;
    if (v.startsWith('http')) return NetworkImage(v);
    if (v.startsWith('assets/')) return AssetImage(v);
    return null;
  }
}
