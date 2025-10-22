import 'package:flutter/material.dart';
// Make sure this file contains SignUpScreen
import 'pages/register_page.dart';
// Import the new file
import 'pages/register_next_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/register': (context) => const SignUpScreen(),
        // This route now correctly uses SignUpNextScreen from its own file
        '/register-next': (context) => const SignUpNextScreen(),
      },
    );
  }
}

// A new widget for your home screen that can navigate
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatTranz'),
        backgroundColor: const Color.fromARGB(255, 58, 96, 183),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text('Go to Register Page'),
            ),
          ],
        ),
      ),
    );
  }
}
