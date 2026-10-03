import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../screens/agreement_screen.dart';
import '../widgets/app_dialog.dart';
import 'auth_service.dart';

/// Tracks which privacy policy version the user accepted.
class PolicyService {
  PolicyService._();

  static const String _versionKey = 'policy_accepted_version';

  /// Records acceptance of the current policy version.
  static Future<void> markAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.policyAcceptedKey, true);
      await prefs.setInt(_versionKey, AppConstants.privacyPolicyVersion);
    } catch (e) {
      if (kDebugMode) debugPrint('Policy accept write failed: $e');
    }
  }

  /// True when the user accepted an older version than the app ships.
  /// Acceptances recorded before versioning count as version 1.
  static Future<bool> needsReacceptance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(AppConstants.policyAcceptedKey) ?? false)) {
        return true;
      }
      final accepted = prefs.getInt(_versionKey) ?? 1;
      return accepted < AppConstants.privacyPolicyVersion;
    } catch (e) {
      if (kDebugMode) debugPrint('Policy version read failed: $e');
      return false;
    }
  }

  static bool _open = false;

  /// Blocking "Privacy policy updated" dialog when needed: Review opens the
  /// Privacy Agreement (accept to continue), Log out ends the session.
  static Future<void> checkAndPrompt(BuildContext context) async {
    if (_open || !await needsReacceptance() || !context.mounted) return;
    _open = true;
    try {
      while (true) {
        if (!context.mounted) return;
        final review = await AppDialog.confirm(
          context,
          title: 'Privacy policy updated',
          message:
              'Review and accept the updated policy to keep using GemEye.',
          confirmLabel: 'Review',
          cancelLabel: 'Log out',
          type: AppDialogType.info,
          icon: Icons.policy_rounded,
          blocking: true,
        );
        if (!review) {
          await AuthService.endSession();
          return;
        }
        if (!context.mounted) return;
        final accepted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
              builder: (_) => const AgreementScreen(reaccept: true)),
        );
        if (accepted == true) return;
      }
    } finally {
      _open = false;
    }
  }
}
