import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles the WebRTC audio connection lifecycle for a call document in Firestore.
/// Signaling model:
///   calls/{callId}
///      - offer: {sdp, type}
///      - answer: {sdp, type}
///      - (status field managed by CallService)
///      candidates/ (subcollection)
///        - {candidate, sdpMid, sdpMLineIndex, from: 'caller'|'receiver', ts}
class VoiceCallService {
  final _firestore = FirebaseFirestore.instance;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  bool _isCaller = false;
  bool _started = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _candSub;

  /// Request microphone and prepare local audio stream.
  Future<void> _initLocalMedia() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception('Microphone permission denied');
    }
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
  }

  Map<String, dynamic> _config() {
    return {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };
  }

  Future<void> startAsCaller(String callId) async {
    if (_started) return; // prevent duplicate
    _isCaller = true;
    _started = true;
    await _initLocalMedia();
    _pc = await createPeerConnection(_config());
    // Add local audio tracks
    for (final track in _localStream!.getAudioTracks()) {
      _pc!.addTrack(track, _localStream!);
    }
    _attachCommonHandlers(callId, from: 'caller');
    final offer = await _pc!.createOffer({'offerToReceiveAudio': true});
    await _pc!.setLocalDescription(offer);
    await _firestore.collection('calls').doc(callId).update({
      'offer': {'sdp': offer.sdp, 'type': offer.type},
    });
    _listenForAnswer(callId);
    _listenForRemoteCandidates(callId);
  }

  Future<void> answerCall(String callId) async {
    if (_started) return; // prevent duplicate
    _isCaller = false;
    _started = true;
    await _initLocalMedia();
    _pc = await createPeerConnection(_config());
    for (final track in _localStream!.getAudioTracks()) {
      _pc!.addTrack(track, _localStream!);
    }
    _attachCommonHandlers(callId, from: 'receiver');
    final doc = await _firestore.collection('calls').doc(callId).get();
    final offer = doc.data()?['offer'];
    if (offer == null) {
      throw Exception('Missing offer in call document');
    }
    await _pc!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'] as String, offer['type'] as String),
    );
    final answer = await _pc!.createAnswer({'offerToReceiveAudio': true});
    await _pc!.setLocalDescription(answer);
    await _firestore.collection('calls').doc(callId).update({
      'answer': {'sdp': answer.sdp, 'type': answer.type},
    });
    _listenForRemoteCandidates(callId);
  }

  void _attachCommonHandlers(String callId, {required String from}) {
    _pc!.onIceCandidate = (candidate) async {
      await _firestore
          .collection('calls')
          .doc(callId)
          .collection('candidates')
          .add({
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            // Use capital L variant per flutter_webrtc API.
            'sdpMLineIndex': candidate.sdpMLineIndex ?? 0,
            'from': from,
            'ts': FieldValue.serverTimestamp(),
          });
    };
    // Remote track handling can be expanded (e.g., UI mute indicator)
    _pc!.onTrack = (event) {
      // Audio automatically plays; no UI widget needed for pure audio.
    };
  }

  void _listenForAnswer(String callId) {
    _docSub = _firestore.collection('calls').doc(callId).snapshots().listen((
      doc,
    ) async {
      final data = doc.data();
      if (data == null) return;
      final answer = data['answer'];
      if (answer != null && _pc != null) {
        final currentRemote = await _pc!.getRemoteDescription();
        if (currentRemote == null) {
          await _pc!.setRemoteDescription(
            RTCSessionDescription(
              answer['sdp'] as String,
              answer['type'] as String,
            ),
          );
        }
      }
    });
  }

  void _listenForRemoteCandidates(String callId) {
    _candSub = _firestore
        .collection('calls')
        .doc(callId)
        .collection('candidates')
        .orderBy('ts')
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data == null) continue;
              final from = data['from'] as String?;
              final shouldApply =
                  (_isCaller && from == 'receiver') ||
                  (!_isCaller && from == 'caller');
              if (shouldApply) {
                final ice = RTCIceCandidate(
                  data['candidate'] as String?,
                  data['sdpMid'] as String?,
                  (data['sdpMLineIndex'] as int?) ?? 0,
                );
                _pc?.addCandidate(ice);
              }
            }
          }
        });
  }

  Future<void> dispose() async {
    await _docSub?.cancel();
    await _candSub?.cancel();
    try {
      await _pc?.close();
    } catch (_) {}
    await _localStream?.dispose();
    _pc = null;
    _localStream = null;
    _started = false;
  }
}

/// Simple helper for muting/unmuting local audio.
class VoiceCallControls {
  final VoiceCallService service;
  VoiceCallControls(this.service);

  bool get isMuted => _muted;
  bool _muted = false;

  void toggleMute() {
    final tracks = service._localStream?.getAudioTracks();
    if (tracks == null) return;
    _muted = !_muted;
    for (final t in tracks) {
      t.enabled = !_muted;
    }
  }
}
