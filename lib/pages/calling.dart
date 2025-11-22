import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/call_service.dart';

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
  Timer? _simulationTimer1;
  Timer? _simulationTimer2;

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
            if (mounted) setState(() => _status = newStatus);
          }
        });
  }

  void _simulateProgress() {
    // Only simulate if still in initial calling state locally.
    _simulationTimer1 = Timer(const Duration(seconds: 2), () async {
      if (_status == 'calling')
        await _service.updateStatus(widget.callId, 'ringing');
    });
    _simulationTimer2 = Timer(const Duration(seconds: 5), () async {
      if (_status == 'ringing')
        await _service.updateStatus(widget.callId, 'answered');
    });
  }

  Future<void> _end() async {
    await _service.endCall(widget.callId);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _sub.cancel();
    _simulationTimer1?.cancel();
    _simulationTimer2?.cancel();
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _callButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    onPressed: _end,
                  ),
                  const SizedBox(width: 40),
                  if (_status != 'answered')
                    _callButton(
                      icon: Icons.call,
                      color: Colors.green,
                      onPressed: () async {
                        if (_status == 'ringing' || _status == 'calling') {
                          await _service.updateStatus(
                            widget.callId,
                            'answered',
                          );
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
      default:
        return _status;
    }
  }
}
