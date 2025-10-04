import 'package:chattranz/pages/conversation.dart';
import 'package:chattranz/pages/login.dart';
import 'package:flutter/material.dart';
import 'pages/register_page.dart'; // Step 1: Import the new page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Step 2: Define the initial route and the list of all available routes
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(), // The widget for the home route
        '/register': (context) =>
            const SignUpScreen(), // The widget for the register route
        '/login': (context) =>
            const LoginPage(), // The widget for the login route
        '/conversation': (context) =>
            const ChatPage(), // The widget for the conversation route
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
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            // Step 3: Add a button to navigate to the register page
            ElevatedButton(
              onPressed: () {
                // When pressed, this will push the '/register' route onto the navigation stack
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
