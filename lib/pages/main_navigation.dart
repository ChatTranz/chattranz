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
          backgroundColor: const Color(0xFF1E1E1E),
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
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.03),
                  offset: const Offset(0, -4),
                  blurRadius: 12,
                ),
                const BoxShadow(
                  color: Colors.black54,
                  offset: Offset(0, 2),
                  blurRadius: 16,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.chat_bubble, 'Chats', 0),
                    _buildNavItem(Icons.group, 'Groups', 1),
                    _buildNavItem(Icons.call, 'Calls', 2),
                    _buildNavItem(Icons.circle_outlined, 'Status', 3),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Neumorphic Navigation Item
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    offset: const Offset(-3, -3),
                    blurRadius: 8,
                  ),
                  const BoxShadow(
                    color: Colors.black54,
                    offset: Offset(3, 3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF4757) : Colors.white38,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF4757) : Colors.white38,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function for call buttons
Widget _buildCallButton({
  required VoidCallback onPressed,
  required IconData icon,
  required String label,
  required Color color,
}) {
  return Column(
    children: [
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
            const BoxShadow(
              color: Colors.black54,
              offset: Offset(0, 8),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
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
          color: Colors.black.withOpacity(0.85),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    offset: const Offset(-8, -8),
                    blurRadius: 20,
                  ),
                  const BoxShadow(
                    color: Colors.black87,
                    offset: Offset(8, 8),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          offset: const Offset(-6, -6),
                          blurRadius: 12,
                        ),
                        const BoxShadow(
                          color: Colors.black54,
                          offset: Offset(6, 6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_rounded,
                      size: 48,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Incoming Call',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    callerName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status == 'ringing' ? 'Ringing…' : 'Calling…',
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCallButton(
                        onPressed: onAccept,
                        icon: Icons.call,
                        label: 'Accept',
                        color: const Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 24),
                      _buildCallButton(
                        onPressed: onDecline,
                        icon: Icons.call_end,
                        label: 'Decline',
                        color: const Color(0xFFFF4757),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
