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
