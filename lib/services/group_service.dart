import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for group-related user actions such as pin/unpin.
///
/// Pinned groups are stored on the user document under the field
/// `pinnedGroups` as an array of group IDs.
class GroupService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  /// Stream of pinned group IDs for the current user.
  static Stream<Set<String>> pinnedGroupsStream() {
    final uid = _uid;
    if (uid == null) return const Stream<Set<String>>.empty();
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data() ?? {};
      final list = List<String>.from(data['pinnedGroups'] ?? const []);
      return list.toSet();
    });
  }

  /// Pin a group for the current user.
  static Future<void> pinGroup(String groupId) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set({
      'pinnedGroups': FieldValue.arrayUnion([groupId]),
    }, SetOptions(merge: true));
  }

  /// Unpin a group for the current user.
  static Future<void> unpinGroup(String groupId) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set({
      'pinnedGroups': FieldValue.arrayRemove([groupId]),
    }, SetOptions(merge: true));
  }
}
