// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter SignUp UI',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//         fontFamily: 'Inter', // A nice, clean font similar to the design
//       ),
//       home: const SignUpScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({super.key});

//   @override
//   State<SignUpScreen> createState() => _SignUpScreenState();
// }

// class _SignUpScreenState extends State<SignUpScreen> {
//   // Controllers for the text fields
//   final _phoneController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();

//   // State to toggle password visibility
//   bool _isPasswordVisible = false;

//   @override
//   void dispose() {
//     // Dispose controllers when the widget is removed from the widget tree
//     _phoneController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF0F2F5),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: Container(
//               margin: const EdgeInsets.symmetric(
//                 horizontal: 24.0,
//                 vertical: 30.0,
//               ),
//               padding: const EdgeInsets.all(24.0),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     spreadRadius: 5,
//                     blurRadius: 15,
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Image.asset(
//                     'assets/chat_icon.png', // <-- Make sure you have this image in your assets folder
//                     height: 100,
//                   ),
//                   const SizedBox(height: 20),

//                   // --- Header Section ---
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       ShaderMask(
//                         blendMode: BlendMode.srcIn,
//                         shaderCallback: (bounds) => const LinearGradient(
//                           colors: [Color(0xFF5B77DB), Color(0xFF17B2F8)],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ).createShader(bounds),
//                         child: const Text(
//                           'Hello Sign Up ',
//                           style: TextStyle(
//                             fontSize: 32,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                       const Text(
//                         '👋',
//                         style: TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'Please fill the details and create account',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 16, color: Colors.black54),
//                   ),
//                   const SizedBox(height: 40),

//                   // --- Form Fields Section ---
//                   _buildTextField(
//                     controller: _phoneController,
//                     hintText: 'Phone Number',
//                     keyboardType: TextInputType.phone,
//                     prefixIcon: Icons.phone_outlined,
//                   ),
//                   const SizedBox(height: 20),
//                   _buildTextField(
//                     controller: _emailController,
//                     hintText: 'E-mail',
//                     keyboardType: TextInputType.emailAddress,
//                     prefixIcon: Icons.mail_outline,
//                   ),
//                   const SizedBox(height: 20),
//                   _buildPasswordField(),
//                   const SizedBox(height: 12),
//                   const Align(
//                     alignment: Alignment.center,
//                     child: Text(
//                       'Password must be at least 6 characters',
//                       style: TextStyle(fontSize: 14, color: Colors.black54),
//                     ),
//                   ),
//                   const SizedBox(height: 30),

//                   // --- Sign Up Button ---
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         final phone = _phoneController.text;
//                         final email = _emailController.text;
//                         final password = _passwordController.text;
//                         print(
//                           'Sign Up attempt with: $phone, $email, $password',
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF17B2F8),
//                         elevation: 4,
//                         shadowColor: Colors.black.withOpacity(1.0),
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: const StadiumBorder(),
//                       ),
//                       child: const Text(
//                         'Sign Up',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // --- Log In Link ---
//                   GestureDetector(
//                     onTap: () {
//                       print('Navigate to Log In screen');
//                     },
//                     child: RichText(
//                       text: const TextSpan(
//                         text: 'Already have an account? ',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.black54,
//                           fontFamily: 'Inter',
//                         ),
//                         children: [
//                           TextSpan(
//                             text: 'Log In',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Color(0xFF4579F2),
//                               fontWeight: FontWeight.bold,
//                               fontFamily: 'Inter',
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Helper method to build a standard text field with the corrected border
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hintText,
//     TextInputType keyboardType = TextInputType.text,
//     IconData? prefixIcon,
//   }) {
//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         hintText: hintText,
//         hintStyle: const TextStyle(color: Colors.black38),
//         filled: true,
//         fillColor: const Color.fromARGB(213, 194, 236, 255),

//         // CORRECTED: Use enabledBorder for the default state
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(20),
//           borderSide: const BorderSide(
//             color: Color.fromARGB(255, 149, 207, 255),
//             width: 1.0,
//           ),
//         ),

//         // CORRECTED: Use focusedBorder for the active state
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(20),
//           borderSide: const BorderSide(
//             color: Color.fromARGB(255, 149, 207, 255),
//             width: 1.0,
//           ),
//         ),

//         contentPadding: const EdgeInsets.symmetric(
//           vertical: 16,
//           horizontal: 20,
//         ),
//         prefixIcon: prefixIcon != null
//             ? Icon(prefixIcon, color: Colors.grey[700])
//             : null,
//       ),
//     );
//   }

//   // Helper method to build the password field with the corrected border
//   Widget _buildPasswordField() {
//     return TextField(
//       controller: _passwordController,
//       obscureText: !_isPasswordVisible,
//       decoration: InputDecoration(
//         hintText: 'Password',
//         hintStyle: const TextStyle(color: Colors.black38),
//         filled: true,
//         fillColor: const Color.fromARGB(213, 194, 236, 255),

//         // CORRECTED: Use enabledBorder for the default state
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(20),
//           borderSide: const BorderSide(
//             color: Color.fromARGB(255, 149, 207, 255),
//             width: 1.0,
//           ),
//         ),

//         // CORRECTED: Use focusedBorder for the active state
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(20),
//           borderSide: const BorderSide(color: Colors.blue, width: 1.0),
//         ),

//         contentPadding: const EdgeInsets.symmetric(
//           vertical: 16,
//           horizontal: 20,
//         ),
//         prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[700]),
//         suffixIcon: IconButton(
//           icon: Icon(
//             _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
//             color: Colors.black45,
//           ),
//           onPressed: () {
//             setState(() {
//               _isPasswordVisible = !_isPasswordVisible;
//             });
//           },
//         ),
//       ),
//     );
//   }
// }




//__________________________________________________________________

import 'package:flutter/material.dart';

// ===================================================================
// ========== Part 1: First Registration Screen (SignUpScreen) ==========
// ===================================================================

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers for the text fields
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State to toggle password visibility
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 30.0,
              ),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 5,
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Make sure you have this image in your assets folder
                  // and have defined it in pubspec.yaml
                  // Image.asset(
                  //   'assets/chat_icon.png',
                  //   height: 100,
                  // ),
                  // Using an icon as a placeholder
                  const Icon(
                    Icons.chat_bubble_rounded,
                    size: 80,
                    color: Color(0xFF17B2F8),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF5B77DB), Color(0xFF17B2F8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Hello Sign Up ',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // This color is masked by the gradient
                          ),
                        ),
                      ),
                      const Text(
                        '👋',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please fill the details and create account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: _phoneController,
                    hintText: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'E-mail',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline,
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Password must be at least 6 characters',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // This line now correctly navigates to the next screen
                        // because we defined the '/register-next' route in main.dart
                        Navigator.pushNamed(context, '/register-next');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17B2F8),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(1.0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      print('Navigate to Log In screen');
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontFamily: 'Inter',
                        ),
                        children: [
                          TextSpan(
                            text: 'Log In',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4579F2),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build a standard text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: const Color.fromARGB(213, 194, 236, 255),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 149, 207, 255),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 149, 207, 255),
            width: 1.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey[700])
            : null,
      ),
    );
  }

  // Helper method to build the password field
  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: const Color.fromARGB(213, 194, 236, 255),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 149, 207, 255),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.blue, width: 1.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[700]),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.black45,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }
}

// =====================================================================
// ========== Part 2: Second Registration Screen (SignUpNextScreen) ==========
// =====================================================================

class SignUpNextScreen extends StatelessWidget {
  const SignUpNextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      // An AppBar provides an automatic back button, which is good UX
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0, // Removes the shadow
        leading: const BackButton(
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          // Layer 1: The Blue Curved Header
          ClipPath(
            clipper: HeaderClipper(),
            child: Container(
              height: screenSize.height * 0.4, // Header takes up 40%
              color: const Color(0xFF2196F3),
            ),
          ),

          // Layer 2: The Main Content
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
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 70,
                        backgroundColor: Color(0xFFBBDEFB), // Lighter blue
                        child: Icon(
                          Icons.person,
                          size: 90,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        bottom: 0, // Changed from top to bottom for better placement
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1976D2), // Darker blue
                            border: Border.all(color: Colors.white, width: 3),
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
                    ],
                  ),
                  const SizedBox(height: 60),
                  const TextField(
                    style: TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                      hintText: 'Your Name',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                       focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2196F3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      onPressed: () {
                        // Handle final registration logic
                        // Pop all routes until you get back to the first screen (or your home page)
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      backgroundColor: const Color(0xFF2196F3),
                      elevation: 4,
                      child: const Icon(Icons.arrow_forward, color: Colors.white),
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

// This is a custom clipper that creates the curved header shape.
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80); // Start from bottom-left
    // Create a quadratic bezier curve to the bottom-right
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 80);
    path.lineTo(size.width, 0); // Line to top-right
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
