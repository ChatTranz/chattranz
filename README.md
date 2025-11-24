# chattranz

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Authentication

Persistent authentication is handled by `AuthGate` (`lib/auth/auth_gate.dart`),
which listens to `FirebaseAuth.instance.authStateChanges()` and shows either
the main navigation (`MainNavigation`) when a user is signed in or the login
screen when signed out. A logout button is available in the profile screen
(`lib/pages/profile_screen.dart`) and triggers `FirebaseAuth.instance.signOut()`,
causing `AuthGate` to automatically display the login screen again.

## Real-Time Voice Calling (WebRTC)

The app now supports peer-to-peer voice calls using WebRTC with Firestore for signaling.

### Dependencies Added
- `flutter_webrtc` for real-time audio
- `permission_handler` for microphone permissions

### Android/iOS Permissions
- Android: `RECORD_AUDIO` added to `AndroidManifest.xml`.
- iOS: `NSMicrophoneUsageDescription` added to `Info.plist`.

### Signaling Data Structure
Each call document in `calls/{callId}` includes:
- Metadata: `callerId`, `receiverId`, `status` (`calling|ringing|answered|ended|declined`)
- `offer`: `{sdp, type}` (created by caller)
- `answer`: `{sdp, type}` (created by receiver)
Subcollection: `calls/{callId}/candidates/*` containing ICE candidates:
`{candidate, sdpMid, sdpMLineIndex, from, ts}`.

### Flow
1. Caller creates call (status `calling`/`ringing`).
2. Receiver taps answer -> status becomes `answered` and generates answer SDP.
3. Caller detects `answered` then sets remote description.
4. ICE candidates exchanged via subcollection and applied automatically.

### Code Entry Points
- WebRTC engine: `lib/services/voice_call_service.dart`
- UI screen: `lib/pages/calling.dart` (starts audio on answer; provides mute button)

### Testing Locally
Run the app on two devices/emulators signed into different accounts:
1. Initiate a call from User A.
2. Accept from User B.
3. Speak into either microphone—audio should transmit.

### Common Issues
- If audio not heard: ensure both granted microphone; check Firestore rules allow reads/writes to `calls/*` and `candidates`.
- Slow connection: add more STUN/TURN servers (a TURN server is required for strict NATs). Example TURN config:
	```dart
	'iceServers': [
		{'urls': 'stun:stun.l.google.com:19302'},
		{
			'urls': 'turn:your.turn.server:3478',
			'username': 'user',
			'credential': 'pass'
		}
	]
	```
- Missing offer: receiver answered before offer stored—retry.

### Enhancements (Next Steps)
- Add call duration tracking.
- Add reconnect / retry logic.
- Add in-call UI (waveform, volume indicator).
- Add TURN server for reliability.
