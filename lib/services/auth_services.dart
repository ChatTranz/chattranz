import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🟢 Sign Up with Email + Password
  Future<User?> registerUser(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // 🔵 Login
  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Mark user online on successful login
      await _firestore.collection('users').doc(result.user!.uid).set({
        'online': true,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // 🟣 Logout
  Future<void> logoutUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'online': false,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await _auth.signOut();
  }

  // 🟠 Add User Profile to Firestore
  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String bio,
    required String photoUrl,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'bio': bio,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔴 Get current user
  User? get currentUser => _auth.currentUser;

  // Helper to fetch online status of a user
  Future<bool> isUserOnline(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return false;
    return (data['online'] as bool?) ?? false;
  }
}
