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
        _avatar = data['profileImage'] as String?;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF252525),
          content: Text(
            'Name cannot be empty',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF252525),
            content: Text(
              'Profile updated',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Profile save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF252525),
            content: Text(
              'Failed to save profile',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'online': false,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF252525),
          content: Text('Logged out', style: TextStyle(color: Colors.white)),
        ),
      );
      // Navigate back to root and clear all routes, auth gate will handle showing login
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  void _openAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252525),
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
                        backgroundColor: const Color(0xFF1E1E1E),
                        backgroundImage: NetworkImage(option.url),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF252525),
                              width: 2,
                            ),
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
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF4757),
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _saving ? null : _saveProfile,
            tooltip: 'Save',
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4757)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      offset: const Offset(-6, -6),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                    const BoxShadow(
                      color: Colors.black45,
                      offset: Offset(6, 6),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF4757,
                                  ).withOpacity(0.5),
                                  offset: const Offset(0, 4),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(0xFF252525),
                              backgroundImage: _resolveAvatarProvider(),
                              child: _resolveAvatarProvider() == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white38,
                                    )
                                  : null,
                            ),
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
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF4757),
                                      Color(0xFFFF6B7A),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFF1E1E1E),
                                    width: 3,
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
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.03),
                            offset: const Offset(-4, -4),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                          const BoxShadow(
                            color: Colors.black87,
                            offset: Offset(4, 4),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Colors.white38,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF252525),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF4757),
                              width: 2.0,
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
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.03),
                            offset: const Offset(-4, -4),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                          const BoxShadow(
                            color: Colors.black87,
                            offset: Offset(4, 4),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _bioController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          labelStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(
                            Icons.info_outline,
                            color: Colors.white38,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF252525),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF4757),
                              width: 2.0,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
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
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _saveProfile,
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.05),
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
                          child: OutlinedButton.icon(
                            onPressed: _openAvatarPicker,
                            icon: const Icon(
                              Icons.image_outlined,
                              color: Color(0xFFFF4757),
                            ),
                            label: const Text(
                              'Change Avatar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF4757),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              side: const BorderSide(
                                color: Color(0xFFFF4757),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  ImageProvider? _resolveAvatarProvider() {
    if (_avatar == null || _avatar!.isEmpty) return null;
    if (_avatar!.startsWith('http')) {
      return NetworkImage(_avatar!);
    } else if (_avatar!.startsWith('assets/')) {
      return AssetImage(_avatar!);
    }
    return null;
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
  String get key => url;
}
