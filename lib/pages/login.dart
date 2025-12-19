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
      backgroundColor: const Color(0xFF1E1E1E), // Dark Neumorphic base
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 30.0,
              ),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E), // Same as background
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  // Light shadow (top-left)
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    offset: const Offset(-6, -6),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                  // Dark shadow (bottom-right)
                  const BoxShadow(
                    color: Colors.black45,
                    offset: Offset(6, 6),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo with Neumorphic container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          offset: const Offset(-5, -5),
                          blurRadius: 12,
                        ),
                        const BoxShadow(
                          color: Colors.black54,
                          offset: Offset(5, 5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Image.asset('assets/loadingLogo.png', height: 120),
                  ),
                  const SizedBox(height: 30),

                  // --- Header Section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Welcome ',
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
                    style: TextStyle(fontSize: 16, color: Colors.white54),
                  ),
                  const SizedBox(height: 40),

                  // --- Form Fields ---
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'E-mail',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline,
                  ),
                  const SizedBox(height: 24),
                  _buildPasswordField(),
                  const SizedBox(height: 10),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        print('Forgot Password clicked');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFF4757),
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFFFF6B7A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Login Button ---
                  _buildNeumorphicButton(
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
                    isLoading: _isLoading,
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
                          color: Colors.white54,
                          fontFamily: 'Inter',
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFFFF4757),
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

  // --- Neumorphic Button ---
  Widget _buildNeumorphicButton({
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF4757), Color(0xFFFF6B7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          // Red glow effect
          BoxShadow(
            color: const Color(0xFFFF4757).withOpacity(0.5),
            offset: const Offset(0, 4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
          // Bottom shadow for depth
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
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Log In',
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
    );
  }

  // --- Neumorphic Text Field ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Inner shadow effect (top-left light)
          BoxShadow(
            color: Colors.white.withOpacity(0.03),
            offset: const Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          // Inner shadow effect (bottom-right dark)
          const BoxShadow(
            color: Colors.black87,
            offset: Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          filled: true,
          fillColor: const Color(0xFF252525),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFF4757), width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.white38)
              : null,
        ),
      ),
    );
  }

  // --- Neumorphic Password Field ---
  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Inner shadow effect (top-left light)
          BoxShadow(
            color: Colors.white.withOpacity(0.03),
            offset: const Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          // Inner shadow effect (bottom-right dark)
          const BoxShadow(
            color: Colors.black87,
            offset: Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          filled: true,
          fillColor: const Color(0xFF252525),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFF4757), width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.white38,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
      ),
    );
  }
}
