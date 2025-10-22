import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SignUpNextScreen extends StatefulWidget {
  const SignUpNextScreen({super.key});

  @override
  State<SignUpNextScreen> createState() => _SignUpNextScreenState();
}

class _SignUpNextScreenState extends State<SignUpNextScreen> {
  XFile? _imageFile;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    // Open the gallery to choose an image
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
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
          // Blue Curved Header
          ClipPath(
            clipper: HeaderClipper(),
            child: Container(
              height: screenSize.height * 0.4,
              color: const Color(0xFF2196F3),
            ),
          ),

          // Main Content
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
                            ? FileImage(File(_imageFile!.path))
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
                        child: MouseRegion(
                          cursor: SystemMouseCursors
                              .click, // 👈 Changes cursor to a hand pointer
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1976D2),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // Name input
                  const TextField(
                    style: TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color.fromARGB(255, 87, 87, 87),
                      ),
                      hintText: 'Your Name',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 0, 0, 0),
                          width: 2.0,
                        ),
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

                  // Next Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      onPressed: () {
                        // Navigate back to the first route (home screen)
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      backgroundColor: const Color(0xFF2196F3),
                      elevation: 4,
                      child: const Icon(
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

// Curved header clipper
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
