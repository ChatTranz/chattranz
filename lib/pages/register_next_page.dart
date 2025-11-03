// For mobile/desktop only. Do NOT import dart:io on web builds.
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignUpNextScreen extends StatefulWidget {
  const SignUpNextScreen({super.key});

  @override
  State<SignUpNextScreen> createState() => _SignUpNextScreenState();
}

class _SignUpNextScreenState extends State<SignUpNextScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _nameController = TextEditingController();
  final String _defaultBio = "Hey there! I'm using ChatTranz 😄";

  XFile? _imageFile;
  Uint8List? _webImageBytes; // preview bytes for web
  bool _isSaving = false;

  // 🔹 Pick image (from gallery)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      if (kIsWeb) {
        // Read bytes for preview on web
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = pickedFile;
          _webImageBytes = bytes;
        });
      } else {
        setState(() => _imageFile = pickedFile);
      }
    }
  }

  // 🔹 Upload image to Firebase Storage (supports Web + Mobile)
  Future<String?> uploadProfileImage(String uid, XFile image) async {
    try {
      final storageRef = _storage.ref().child(
        'profile_pics/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final SettableMetadata meta = SettableMetadata(
        contentType: image.mimeType ?? 'image/jpeg',
      );

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await storageRef.putData(bytes, meta);
      } else {
        final file = File(image.path);
        await storageRef.putFile(file, meta);
      }

      final downloadUrl = await storageRef.getDownloadURL();
      print("✅ Image uploaded successfully: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print('⚠️ Upload failed: $e');
      Fluttertoast.showToast(msg: "Image upload failed!");
      return null;
    }
  }

  // 🔹 Save profile data to Firestore
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

    setState(() => _isSaving = true);

    try {
      print("✅ Starting profile save for UID: ${user.uid}");

      // 🔹 Just use default image
      final imageUrl =
          "https://cdn-icons-png.flaticon.com/512/3135/3135715.png"; // Default avatar

      // 🔹 Write user data to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'bio': _defaultBio,
        'profileImage': imageUrl,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ Firestore write complete!");
      Fluttertoast.showToast(msg: "Profile saved successfully!");

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/chatlist');
      }
    } catch (e, st) {
      print("❌ Firestore error: $e");
      print("🔍 Stacktrace: $st");
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

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Profile picture + edit button
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: const Color.fromARGB(
                          255,
                          145,
                          213,
                          245,
                        ),
                        backgroundImage: _imageFile != null
                            ? (kIsWeb
                                      ? (_webImageBytes != null
                                            ? MemoryImage(_webImageBytes!)
                                            : null)
                                      : FileImage(File(_imageFile!.path)))
                                  as ImageProvider?
                            : null,
                        child: _imageFile == null
                            ? const Icon(
                                Icons.person,
                                size: 90,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1976D2),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // Name input
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color.fromARGB(255, 87, 87, 87),
                      ),
                      hintText: 'Your Name',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2.0),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF2196F3),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Save button
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      backgroundColor: const Color(0xFF2196F3),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 Custom curved header
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
