import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:chattranz/pages/calling.dart';
import 'package:chattranz/pages/conversation.dart';
import 'package:flutter/material.dart';
import 'pages/register_page.dart';
import 'pages/register_next_page.dart';
import 'pages/login.dart';
import 'pages/chatlist.dart';
import 'pages/splash_screen.dart';
import 'auth/auth_gate.dart';

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
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthGate(),
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
        '/calling': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic> && args['callId'] != null) {
            return CallingScreen(
              callId: args['callId'] as String,
              friendId: (args['friendId'] ?? '') as String,
              friendName: (args['friendName'] ?? 'Unknown') as String,
              friendPhotoUrl: args['friendPhotoUrl'] as String?,
            );
          }
          return const Scaffold(
            body: Center(child: Text('Missing call arguments')),
          );
        },
      },
    );
  }
}

// A new widget for your home screen that can navigate
// The previous static home page is replaced by AuthGate based logic.
