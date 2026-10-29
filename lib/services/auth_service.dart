import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ValueNotifier<bool> isGuestNotifier = ValueNotifier<bool>(false);

  bool get isGuest => isGuestNotifier.value;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  void signInAsGuest() {
    isGuestNotifier.value = true;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    isGuestNotifier.value = false;
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    isGuestNotifier.value = false;
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    if (displayName != null && displayName.trim().isNotEmpty) {
      await credential.user?.updateDisplayName(displayName.trim());
      await credential.user?.reload();
    }

    return credential;
  }

  Future<void> sendPasswordReset({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    isGuestNotifier.value = false;
    await _auth.signOut();
  }

  static String getReadableErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      final code = e.code.toLowerCase();
      final msg = (e.message ?? '').toLowerCase();

      if (code == 'configuration-not-found' ||
          msg.contains('configuration_not_found') ||
          msg.contains('configuration not found')) {
        return 'Firebase Authentication is not activated in Firebase Console for project "schedly-b3bea". Please open Firebase Console > Build > Authentication > Sign-in method and enable "Email/Password".';
      }
      if (code == 'user-not-found' || msg.contains('user-not-found')) {
        return 'No user registered with this email address. Please tap "Register now" to create an account.';
      }
      if (code == 'wrong-password' || msg.contains('wrong-password')) {
        return 'Incorrect password. Please verify and try again.';
      }
      if (code == 'invalid-email' || msg.contains('invalid-email')) {
        return 'Please enter a valid email address.';
      }
      if (code == 'user-disabled' || msg.contains('user-disabled')) {
        return 'This account has been disabled.';
      }
      if (code == 'email-already-in-use' || msg.contains('email-already-in-use')) {
        return 'An account already exists with this email address.';
      }
      if (code == 'operation-not-allowed' || msg.contains('operation-not-allowed')) {
        return 'Email/Password sign-in is disabled in Firebase Console. Go to Firebase Console > Authentication > Sign-in method to enable it.';
      }
      if (code == 'weak-password' || msg.contains('weak-password')) {
        return 'Password must be at least 6 characters.';
      }
      if (code == 'invalid-credential' || msg.contains('invalid-credential')) {
        return 'Invalid email or password. Please verify your credentials.';
      }
      if (code == 'too-many-requests' || msg.contains('too-many-requests')) {
        return 'Too many failed attempts. Please wait a few moments and try again.';
      }
      if (code == 'network-request-failed' || msg.contains('network-request-failed')) {
        return 'Network connection error. Please check your internet connection.';
      }
      if (e.message != null && e.message!.isNotEmpty && e.message != 'Error') {
        return e.message!;
      }
    }

    final str = e.toString();
    if (str.contains('CONFIGURATION_NOT_FOUND') || str.contains('configuration-not-found')) {
      return 'Firebase Authentication is not activated in Firebase Console for project "schedly-b3bea". Go to Firebase Console > Authentication > Sign-in method and enable "Email/Password".';
    }

    return 'Authentication error: ${e.toString()}';
  }
}
