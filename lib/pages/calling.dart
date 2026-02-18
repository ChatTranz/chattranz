import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/call_service.dart';
import '../services/voice_call_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallingScreen extends StatefulWidget {
  final String callId;
  final String friendId;
  final String friendName;
  final String? friendPhotoUrl;
  const CallingScreen({
    super.key,
    required this.callId,
    required this.friendId,
    required this.friendName,
    this.friendPhotoUrl,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> _sub;
  String _status = 'calling';
  final _service = CallService();
  final _voice = VoiceCallService();
  VoiceCallControls? _controls;
  bool _isCaller = false;
  bool _audioStarted = false;
  Timer? _simulationTimer1;
  Timer? _simulationTimer2; // kept for backward-compat; not used to auto-answer
  bool _popped = false; // prevent double pop when remote ends/declines

  @override
  void initState() {
    super.initState();
    _listen();
    _simulateProgress();
  }

  void _listen() {
    _sub = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((doc) {
          final data = doc.data();
          if (data != null) {
            final newStatus = data['status'] as String? ?? 'calling';
            final callerId = data['callerId'] as String?;
            // Determine role using FirebaseAuth directly (safer) if available.
            try {
              final authUser = FirebaseAuth.instance.currentUser;
              if (authUser != null && callerId != null) {
                _isCaller = authUser.uid == callerId;
              }
            } catch (_) {}
            if (mounted) setState(() => _status = newStatus);
            // Auto-close screen if remote declines or ends the call.
            if ((newStatus == 'declined' || newStatus == 'ended') && !_popped) {
              _popped = true;
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }
            // Start caller audio once remote answers.
            if (newStatus == 'answered' && _isCaller && !_audioStarted) {
              _startCallerAudio();
            }
          }
        });
  }

  void _simulateProgress() {
    // Only simulate if still in initial calling state locally.
    _simulationTimer1 = Timer(const Duration(seconds: 2), () async {
      if (_status == 'calling')
        await _service.updateStatus(widget.callId, 'ringing');
    });
    // NOTE: removed automatic transition to 'answered' after a timeout.
    // The call should only be answered by an explicit user action.
  }

  Future<void> _end() async {
    _popped =
        true; // Set flag before ending to prevent listener from also popping
    await _service.endCall(widget.callId);
    await _voice.dispose();
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    _simulationTimer1?.cancel();
    _simulationTimer2?.cancel();
    _voice.dispose();
    super.dispose();
  }

  Widget _callButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: color,
      shape: const CircleBorder(),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 14, 14, 14),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 14, 14),
        title: Text(
          _status == 'answered' ? 'In Call' : 'Calling ...',
          style: const TextStyle(
            color: Color.fromARGB(255, 236, 236, 236),
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _end,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.1),
            CircleAvatar(
              radius: 60,
              backgroundImage: widget.friendPhotoUrl != null
                  ? NetworkImage(widget.friendPhotoUrl!)
                  : null,
              backgroundColor: Colors.grey.shade800,
              child: widget.friendPhotoUrl == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              widget.friendName,
              style: const TextStyle(
                color: Color.fromARGB(255, 236, 236, 236),
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusLabel(),
              style: const TextStyle(
                color: Color.fromARGB(255, 236, 236, 236),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: _status == 'answered' || _isCaller
                  ? SizedBox(
                      width: 200,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _end,
                        icon: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 28,
                        ),
                        label: const Text(
                          'End Call',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _callButton(
                          icon: Icons.call_end,
                          color: Colors.red,
                          onPressed: _end,
                        ),
                        const SizedBox(width: 40),
                        _callButton(
                          icon: Icons.call,
                          color: Colors.green,
                          onPressed: () async {
                            if (_status == 'ringing' || _status == 'calling') {
                              await _service.updateStatus(
                                widget.callId,
                                'answered',
                              );
                              // Receiver starts audio immediately after answering.
                              _startReceiverAudio();
                            }
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel() {
    switch (_status) {
      case 'calling':
        return 'Calling…';
      case 'ringing':
        return 'Ringing…';
      case 'answered':
        return 'Connected';
      case 'ended':
        return 'Ended';
      case 'declined':
        return 'Declined';
      default:
        return _status;
    }
  }

  Future<void> _startCallerAudio() async {
    try {
      await _voice.startAsCaller(widget.callId);
      _controls = VoiceCallControls(_voice);
      _audioStarted = true;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Caller audio start failed: $e');
    }
  }

  Future<void> _startReceiverAudio() async {
    if (_audioStarted) return;
    try {
      await _voice.answerCall(widget.callId);
      _controls = VoiceCallControls(_voice);
      _audioStarted = true;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Receiver audio start failed: $e');
    }
  }
}
