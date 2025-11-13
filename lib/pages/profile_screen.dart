import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _avatar; // stores selected avatar key

  // Predefined avatar choices: list of network image URLs provided.
  final List<_AvatarOption> _avatarOptions = const [
    _AvatarOption(
      url: 'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
    ),
    _AvatarOption(
      url: 'https://cdn-icons-png.flaticon.com/512/4140/4140052.png',
    ),
    _AvatarOption(
      url: 'https://cdn-icons-png.flaticon.com/512/4140/4140037.png',
    ),
    _AvatarOption(
      url: 'https://cdn-icons-png.flaticon.com/512/4140/4140040.png',
    ),
    _AvatarOption(
      url: 'https://cdn-icons-png.flaticon.com/512/4140/4140057.png',
    ),
    _AvatarOption(
      url: 'https://cdn-icons-png.flaticon.com/512/4140/4140061.png',
    ),
    _AvatarOption(
      url: 'https://cdn-icons-png.flaticon.com/512/4140/4140073.png',
    ),
    _AvatarOption(
      url: 'https://cdn-icons-png.flaticon.com/512/4140/4140080.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        _nameController.text = (data['name'] ?? '') as String;
        _bioController.text =
            (data['bio'] ?? "Hey there! I'm using ChatTranz 😄") as String;
        _avatar = data['profileImage'] as String?; // may be URL or asset path
      } else {
        _bioController.text = "Hey there! I'm using ChatTranz 😄";
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'profileImage': _avatar,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (e) {
      debugPrint('Profile save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openAvatarPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            itemCount: _avatarOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final option = _avatarOptions[index];
              final isSelected = _avatar == option.key;
              return InkWell(
                onTap: () {
                  setState(() => _avatar = option.key);
                  Navigator.pop(context);
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: NetworkImage(option.url),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF2196F3),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _saving ? null : _saveProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: _resolveAvatarProvider(),
                          child: _resolveAvatarProvider() == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _openAvatarPicker,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1976D2),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.info_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _openAvatarPicker,
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Change Avatar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  ImageProvider? _resolveAvatarProvider() {
    if (_avatar == null || _avatar!.isEmpty) return null;
    // If starts with http treat as network URL, else assume asset path.
    if (_avatar!.startsWith('http')) {
      return NetworkImage(_avatar!);
    } else if (_avatar!.startsWith('assets/')) {
      return AssetImage(_avatar!);
    }
    return null; // fallback (could build more logic here)
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}

class _AvatarOption {
  final String url;
  const _AvatarOption({required this.url});
  String get key => url; // use url directly
}
