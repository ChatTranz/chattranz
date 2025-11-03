import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignUpNextScreen extends StatefulWidget {
  const SignUpNextScreen({super.key});

  @override
  State<SignUpNextScreen> createState() => _SignUpNextScreenState();
}

class _SignUpNextScreenState extends State<SignUpNextScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  String _defaultBio = "Hey there! I'm using ChatTranz 😄";
  bool _isSaving = false;

  // 🔹 Predefined avatar list (you can add your own URLs)
  final List<String> _avatars = [
    "https://cdn-icons-png.flaticon.com/512/4140/4140048.png",
    "https://cdn-icons-png.flaticon.com/512/4140/4140052.png",
    "https://cdn-icons-png.flaticon.com/512/4140/4140037.png",
    "https://cdn-icons-png.flaticon.com/512/4140/4140040.png",
    "https://cdn-icons-png.flaticon.com/512/4140/4140057.png",
    "https://cdn-icons-png.flaticon.com/512/4140/4140061.png",
    "https://cdn-icons-png.flaticon.com/512/4140/4140073.png",
    "https://cdn-icons-png.flaticon.com/512/4140/4140080.png",
  ];

  String? _selectedAvatar;

  // 🔹 Save profile to Firestore
  Future<void> _saveProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      Fluttertoast.showToast(msg: "User not logged in!");
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your name!");
      return;
    }

    if (_selectedAvatar == null) {
      Fluttertoast.showToast(msg: "Please select an avatar!");
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'bio': _defaultBio,
        'profileImage': _selectedAvatar,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Fluttertoast.showToast(msg: "Profile saved successfully!");
      Navigator.pushReplacementNamed(context, '/chatlist');
    } catch (e) {
      print("❌ Firestore error: $e");
      Fluttertoast.showToast(msg: "Failed to save profile!");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Blue curved header
          ClipPath(
            clipper: HeaderClipper(),
            child: Container(
              height: screenSize.height * 0.4,
              color: const Color(0xFF2196F3),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Profile Setup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Selected Avatar Preview
                    CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          const Color.fromARGB(255, 145, 213, 245),
                      backgroundImage: _selectedAvatar != null
                          ? NetworkImage(_selectedAvatar!)
                          : null,
                      child: _selectedAvatar == null
                          ? const Icon(Icons.person,
                              size: 80, color: Colors.white)
                          : null,
                    ),

                    const SizedBox(height: 25),

                    // Avatar Grid
                    const Text(
                      "Select Your Avatar",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _avatars.length,
                      itemBuilder: (context, index) {
                        final avatar = _avatars[index];
                        final isSelected = _selectedAvatar == avatar;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedAvatar = avatar);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.transparent,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(avatar),
                              radius: 30,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Name input
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline,
                            color: Color.fromARGB(255, 87, 87, 87)),
                        hintText: 'Your Name',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFF2196F3), width: 2.0),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: FloatingActionButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        backgroundColor: const Color(0xFF2196F3),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Icon(Icons.arrow_forward,
                                color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Curved header clipper
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 80);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
