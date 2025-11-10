import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:chattranz/pages/calling.dart';
import 'package:chattranz/pages/conversation.dart';
import 'package:chattranz/pages/login.dart';
import 'package:flutter/material.dart';
// Make sure this file contains SignUpScreen
import 'pages/register_page.dart';
// Import the new file
import 'pages/register_next_page.dart';
import 'pages/chatlist.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        '/register-next': (context) =>
            const SignUpNextScreen(), // The widget for the register route
        '/login': (context) =>
            const LoginScreen(), // The widget for the login route
        '/chatlist': (context) =>
            const ChatListPage(), // The widget for the chatlist route
        '/conversation': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic> &&
              args['friendId'] != null &&
              args['friendName'] != null) {
            return ChatPage(
              friendId: args['friendId'] as String,
              friendName: args['friendName'] as String,
            );
          }
          // Fallback UI if arguments are missing or of wrong type
          return const Scaffold(
            body: Center(
              child: Text('Missing friendId or friendName for ChatPage'),
            ),
          );
        }, // The widget for the conversation route
        '/calling': (context) =>
            const CallingScreen(), // The widget for the calling route
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
            const Text('Welcome!', style: TextStyle(fontSize: 24)),
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
