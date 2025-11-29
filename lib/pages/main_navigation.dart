import 'package:chattranz/pages/chatlist.dart';
import 'package:flutter/material.dart';
import 'chatlist.dart';
import 'groups_screen.dart';
import 'calls_screen.dart';
import 'calling.dart';
import 'status_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/call_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final _callService = CallService();

  final List<Widget> _pages = [
    const ChatListPage(), // your current chat list (Home)
    const GroupsScreen(),
    const CallsScreen(),
    const StatusScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Removed unused currentUser variable.
    return StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
      stream: _callService.incomingCallsStream(),
      builder: (context, snapshot) {
        final incoming = snapshot.data ?? [];
        DocumentSnapshot<Map<String, dynamic>>? activeIncoming;
        if (incoming.isNotEmpty) {
          incoming.sort((a, b) {
            final ta = a.data()?['startedAt'] as Timestamp?;
            final tb = b.data()?['startedAt'] as Timestamp?;
            return (tb?.millisecondsSinceEpoch ?? 0) -
                (ta?.millisecondsSinceEpoch ?? 0);
          });
          activeIncoming = incoming.first;
        }

        return Scaffold(
          body: Stack(
            children: [
              _pages[_selectedIndex],
              if (activeIncoming != null)
                _IncomingCallOverlay(
                  callDoc: activeIncoming,
                  onAccept: () async {
                    // Update status to answered first.
                    await _callService.updateStatus(
                      activeIncoming!.id,
                      'answered',
                    );
                    // Extract caller info from call document.
                    final data = activeIncoming.data();
                    final callerId = data?['callerId'] as String? ?? '';
                    final callerName =
                        data?['callerName'] as String? ?? 'Unknown';
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CallingScreen(
                            callId: activeIncoming!.id,
                            friendId: callerId,
                            friendName: callerName,
                            friendPhotoUrl: null, // Could be fetched if needed
                          ),
                        ),
                      );
                    }
                  },
                  onDecline: () async {
                    await _callService.declineCall(activeIncoming!.id);
                  },
                ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF00BCD4),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble),
                label: 'Chats',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
              BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
              BottomNavigationBarItem(
                icon: Icon(Icons.circle_outlined),
                label: 'Status',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IncomingCallOverlay extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> callDoc;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _IncomingCallOverlay({
    required this.callDoc,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final data = callDoc.data() ?? {};
    final callerName = data['callerName'] as String? ?? 'Unknown';
    final status = data['status'] as String? ?? 'calling';
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Incoming Call',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      callerName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(status == 'ringing' ? 'Ringing…' : 'Calling…'),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: onAccept,
                          icon: const Icon(Icons.call),
                          label: const Text('Accept'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: onDecline,
                          icon: const Icon(Icons.call_end),
                          label: const Text('Decline'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
