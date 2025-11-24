import 'package:chattranz/services/auth_services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter/material.dart';
import 'register_page.dart'; // <-- Import your register page if you want navigation
import 'main_navigation.dart'; // <-- Import main navigation page

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
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
                  Image.asset(
                    'assets/chat_icon.png', // same icon as register page
                    height: 100,
                  ),
                  const SizedBox(height: 20),

                  // --- Header Section ---
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
                          'Welcome Back ',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                    'Login to your account to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),

                  // --- Form Fields ---
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'E-mail',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline,
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 10),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        print('Forgot Password clicked');
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF4579F2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- Login Button ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();

                        if (email.isEmpty || password.isEmpty) {
                          Fluttertoast.showToast(
                            msg: "Please enter email and password",
                          );
                          return;
                        }

                        if (!mounted) return;
                        setState(() => _isLoading = true);

                        try {
                          final user = await _authService.loginUser(
                            email,
                            password,
                          );
                          if (user != null) {
                            Fluttertoast.showToast(msg: "Login Successful!");
                            if (!mounted)
                              return; // stop if disposed before navigation
                            await Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainNavigation(),
                              ),
                            );
                          }
                        } catch (e) {
                          Fluttertoast.showToast(
                            msg: "Login failed: ${e.toString()}",
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17B2F8),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(1.0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Sign Up Link ---
                  GestureDetector(
                    onTap: () {
                      // Navigate to Register screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontFamily: 'Inter',
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
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

  // --- Email Field Helper ---
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
          borderSide: const BorderSide(color: Colors.blue, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.blue, width: 1.0),
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

  // --- Password Field Helper ---
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
          borderSide: const BorderSide(color: Colors.blue, width: 1.0),
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
