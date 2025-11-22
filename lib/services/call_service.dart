import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Starts a new call document and returns its id.
  Future<String> startCall({
    required String receiverId,
    required String receiverName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final doc = await _firestore.collection('calls').add({
      'callerId': user.uid,
      'callerName': user.displayName ?? 'You',
      'receiverId': receiverId,
      'receiverName': receiverName,
      'participants': [user.uid, receiverId],
      'status': 'calling', // calling | ringing | answered | ended
      'startedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateStatus(String callId, String status) async {
    final data = <String, dynamic>{'status': status};
    if (status == 'answered') {
      data['answeredAt'] = FieldValue.serverTimestamp();
    } else if (status == 'ended') {
      data['endedAt'] = FieldValue.serverTimestamp();
    }
    await _firestore.collection('calls').doc(callId).update(data);
  }

  Future<void> endCall(String callId) async => updateStatus(callId, 'ended');

  /// Stream of calls involving current user ordered by start time desc.
  Stream<QuerySnapshot<Map<String, dynamic>>> myCallsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('calls')
        .where('participants', arrayContains: user.uid)
        .orderBy('startedAt', descending: true)
        .snapshots();
  }
}

class CallLogEntry {
  final String id;
  final String otherName;
  final bool isOutgoing;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;

  CallLogEntry({
    required this.id,
    required this.otherName,
    required this.isOutgoing,
    required this.status,
    required this.startedAt,
    required this.endedAt,
  });

  factory CallLogEntry.fromDoc(
    String id,
    Map<String, dynamic> data,
    String currentUserId,
  ) {
    final callerId = data['callerId'] as String? ?? '';
    final isOutgoing = callerId == currentUserId;
    final otherName = isOutgoing
        ? (data['receiverName'] as String? ?? 'Unknown')
        : (data['callerName'] as String? ?? 'Unknown');
    final Timestamp? startedTs = data['startedAt'] as Timestamp?;
    final Timestamp? endedTs = data['endedAt'] as Timestamp?;
    return CallLogEntry(
      id: id,
      otherName: otherName,
      isOutgoing: isOutgoing,
      status: data['status'] as String? ?? 'calling',
      startedAt: startedTs?.toDate(),
      endedAt: endedTs?.toDate(),
    );
  }
}
