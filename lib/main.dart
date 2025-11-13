import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:chattranz/pages/calling.dart';
import 'package:chattranz/pages/conversation.dart';
import 'package:chattranz/pages/login.dart';
import 'package:flutter/material.dart';
import 'pages/register_page.dart';
import 'pages/register_next_page.dart';
import 'pages/chatlist.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase only once
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

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
        '/register-next': (context) => const SignUpNextScreen(),
        '/login': (context) => const LoginScreen(),
        '/chatlist': (context) => const ChatListPage(),
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
          return const Scaffold(
            body: Center(
              child: Text('Missing friendId or friendName for ChatPage'),
            ),
          );
        },
        '/calling': (context) => const CallingScreen(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatTranz'),
        backgroundColor: Color.fromARGB(255, 58, 96, 183),
        foregroundColor: Colors.white,
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
