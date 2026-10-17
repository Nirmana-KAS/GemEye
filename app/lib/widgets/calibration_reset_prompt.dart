import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../screens/calibration_screen.dart';
import '../services/calibration_service.dart';
import 'app_dialog.dart';

/// Support can reset a calibration from the dashboard. The app checks on
/// start (Home), on resume and before grading; when the current session was
/// reset it is marked expired and the user is asked to recalibrate.
class CalibrationResetPrompt {
  CalibrationResetPrompt._();

  static bool _showing = false;
  static bool _watching = false;
  static final _ResumeObserver _observer = _ResumeObserver();

  /// Returns true when the current session was reset (the dialog was shown,
  /// unless another one is already open or there is no screen to show it on).
  static Future<bool> check([BuildContext? context]) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Calibration reset check skipped: $e');
      return false;
    }
    if (!await CalibrationService.checkServerReset()) return false;
    final ctx = context ?? AppRoutes.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted || _showing) return true;
    _showing = true;
    try {
      final recalibrate = await AppDialog.confirm(
        ctx,
        title: 'Calibration reset',
        message: 'Your calibration was reset by support. Please recalibrate '
            'before grading.',
        confirmLabel: 'Recalibrate',
        cancelLabel: 'Later',
        icon: Icons.tune_rounded,
      );
      if (recalibrate && ctx.mounted) {
        AppRoutes.push(ctx, const CalibrationScreen(popOnSave: true));
      }
    } finally {
      _showing = false;
    }
    return true;
  }

  /// Checks again whenever the app returns to the foreground (once, main.dart).
  static void watchResume() {
    if (_watching) return;
    _watching = true;
    WidgetsBinding.instance.addObserver(_observer);
  }
}

class _ResumeObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(CalibrationResetPrompt.check());
    }
  }
}
