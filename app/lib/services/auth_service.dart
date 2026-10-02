import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/routes.dart';
import '../screens/login_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> registerWithEmail(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  static bool _isEndingSession = false;

  /// The single logout path for the app. Closes any open dialog or sheet,
  /// runs [beforeSignOut] (e.g. account deletion), signs out, then clears the
  /// navigation stack to LoginScreen. Re-entrant calls are ignored.
  /// Returns false if [beforeSignOut] or sign-out failed (nothing navigates).
  static Future<bool> endSession({
    Future<void> Function()? beforeSignOut,
  }) async {
    if (_isEndingSession) return false;
    _isEndingSession = true;
    try {
      final nav = AppRoutes.navigatorKey.currentState;
      nav?.popUntil((route) => route is! PopupRoute);
      if (beforeSignOut != null) await beforeSignOut();
      await AuthService().signOut();
      AppRoutes.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('endSession failed: $e');
      return false;
    } finally {
      _isEndingSession = false;
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  String getFirstName() {
    final user = _auth.currentUser;
    if (user == null) return 'User';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!.split(' ').first;
    }
    return user.email?.split('@').first ?? 'User';
  }
}
