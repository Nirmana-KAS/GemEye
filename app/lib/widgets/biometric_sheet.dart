import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../config/theme.dart';
import 'app_buttons.dart';

enum _BioState { idle, failed, verified }

/// "Verify it's you" bottom sheet (Security Dialogs 21a). Uses the
/// fingerprint / face sensor through local_auth; "Use PIN instead" falls
/// back to the device credential (PIN, pattern or password).
class BiometricSheet extends StatefulWidget {
  /// What the user is about to do, e.g. "change your password".
  final String action;

  const BiometricSheet({super.key, required this.action});

  /// Returns true once the user is verified. Devices without any screen
  /// lock cannot verify, so they pass straight through (the sensitive
  /// action itself still needs the account password or Google sign-in).
  static Future<bool> verify(BuildContext context,
      {required String action}) async {
    try {
      if (!await LocalAuthentication().isDeviceSupported()) return true;
    } catch (e) {
      if (kDebugMode) debugPrint('local_auth support check failed: $e');
      return true;
    }
    if (!context.mounted) return false;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.card,
      barrierColor: AppColors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BiometricSheet(action: action),
    );
    return ok ?? false;
  }

  @override
  State<BiometricSheet> createState() => _BiometricSheetState();
}

class _BiometricSheetState extends State<BiometricSheet> {
  final LocalAuthentication _auth = LocalAuthentication();
  _BioState _state = _BioState.idle;
  bool _hasBiometrics = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      _hasBiometrics = await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('local_auth biometrics check failed: $e');
    }
    if (!mounted) return;
    setState(() {});
    if (_hasBiometrics) {
      _authenticate(biometricOnly: true);
    } else {
      _authenticate(biometricOnly: false);
    }
  }

  Future<void> _authenticate({required bool biometricOnly}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _state = _BioState.idle;
    });
    var ok = false;
    try {
      ok = await _auth.authenticate(
        localizedReason: 'Confirm your identity to ${widget.action}.',
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('local_auth failed: ${e.code}');
    } catch (e) {
      if (kDebugMode) debugPrint('local_auth failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _state = ok ? _BioState.verified : _BioState.failed;
    });
    if (ok) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color bg, Color fg, String text, Color textColor) =
        switch (_state) {
      _BioState.idle => (
          Icons.fingerprint_rounded,
          AppColors.surface,
          AppColors.primary,
          _hasBiometrics
              ? 'Touch the fingerprint sensor'
              : 'Use your screen lock to continue',
          AppColors.textSecondary
        ),
      _BioState.failed => (
          Icons.fingerprint_rounded,
          AppColors.errorTint,
          AppColors.errorText,
          'Not recognised. Try again.',
          AppColors.errorText
        ),
      _BioState.verified => (
          Icons.check_rounded,
          AppColors.successTint,
          AppColors.successText,
          'Verified',
          AppColors.successText
        ),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text("Verify it's you", style: AppText.sectionHeader),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Confirm your identity to ${widget.action}.',
              textAlign: TextAlign.center,
              style: AppText.body14
                  .copyWith(height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Semantics(
              button: true,
              label: 'Fingerprint',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _busy
                    ? null
                    : () => _authenticate(biometricOnly: _hasBiometrics),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(icon, size: 44, color: fg),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(text,
                style: AppText.body14Medium
                    .copyWith(fontSize: 13, color: textColor)),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Transform.translate(
                  offset: const Offset(-AppSpacing.md, 0),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      minimumSize: const Size(
                          AppSpacing.touchTarget, AppSpacing.touchTarget),
                      textStyle: AppText.button,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(AppSpacing.md, 0),
                  child: TextLinkButton(
                    label: 'Use PIN instead',
                    icon: Icons.pin_rounded,
                    onPressed: _busy
                        ? null
                        : () => _authenticate(biometricOnly: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
