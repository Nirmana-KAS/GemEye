import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/routes.dart';
import '../screens/login_screen.dart';
import '../widgets/app_dialog.dart';
import 'account_service.dart';
import 'api_client.dart';
import 'heatmap_service.dart';

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
    HeatmapService.clearCache();
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

  /// True when the account has an email/password credential.
  bool get hasPassword =>
      currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  /// True when the account signs in with Google only (no password to change).
  bool get isGoogleOnly =>
      !hasPassword &&
      (currentUser?.providerData.any((p) => p.providerId == 'google.com') ??
          false);

  /// Re-authenticates an email/password account (required before
  /// sensitive changes such as a new password or account deletion).
  Future<void> reauthenticateWithPassword(String password) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: password),
    );
  }

  /// Re-authenticates a Google account. Returns false if the user cancelled.
  Future<bool> reauthenticateWithGoogle() async {
    final user = currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user');
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return false;
    final googleAuth = await googleUser.authentication;
    await user.reauthenticateWithCredential(GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    ));
    return true;
  }

  // Session expiry

  static const Set<String> _sessionErrorCodes = {
    'user-token-expired',
    'user-disabled',
  };

  static bool _sessionDialogOpen = false;

  /// True for FirebaseAuth errors that mean the user must log in again.
  static bool isSessionError(Object e) =>
      e is FirebaseAuthException && _sessionErrorCodes.contains(e.code);

  /// Shows the blocking "Session expired" dialog and logs out when [e] is a
  /// session error. Returns true when it handled [e].
  static bool handleSessionError(Object e) {
    if (!isSessionError(e)) return false;
    showSessionExpired();
    return true;
  }

  /// Blocking "Session expired" dialog, then the single logout path.
  static Future<void> showSessionExpired() async {
    final context = AppRoutes.navigatorKey.currentContext;
    if (context == null || _sessionDialogOpen) return;
    _sessionDialogOpen = true;
    try {
      await AppDialog.alert(
        context,
        title: 'Session expired',
        message: 'Please log in again.',
        actionLabel: 'Log in',
        type: AppDialogType.warning,
        icon: Icons.lock_clock_rounded,
        blocking: true,
      );
    } finally {
      _sessionDialogOpen = false;
    }
    await endSession();
  }

  static bool _deadSessionHandling = false;

  /// The shared handler for a dead server session (ApiClient.sessionLostHandler):
  /// the account was deleted, or the token could not be refreshed. Shows the
  /// dialog once, clears local data and goes to Login. Does nothing when
  /// nobody is signed in or it is already running.
  static Future<void> handleDeadSession(ApiException e) async {
    if (_deadSessionHandling || FirebaseAuth.instance.currentUser == null) {
      return;
    }
    _deadSessionHandling = true;
    try {
      final context = AppRoutes.navigatorKey.currentContext;
      if (context != null) {
        final deleted = e.code == ApiErrorCode.accountDeleted;
        await AppDialog.alert(
          context,
          title: deleted ? 'Account deleted' : 'Session expired',
          message: deleted
              ? 'This account has been deleted. You will be signed out.'
              : 'Please log in again.',
          actionLabel: 'Log in',
          type: deleted ? AppDialogType.danger : AppDialogType.warning,
          icon: deleted ? Icons.person_off_rounded : Icons.lock_clock_rounded,
          blocking: true,
        );
      }
      await endSession(beforeSignOut: AccountService.clearLocalData);
    } finally {
      _deadSessionHandling = false;
    }
  }

  /// Reloads the signed-in user; an expired or disabled account shows the
  /// "Session expired" dialog. Other errors (e.g. offline) are ignored.
  static Future<void> verifySession() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
    } catch (e) {
      if (!handleSessionError(e) && kDebugMode) {
        debugPrint('verifySession: $e');
      }
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
