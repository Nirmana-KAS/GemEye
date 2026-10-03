import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../models/app_notification.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/biometric_sheet.dart';
import '../widgets/gem_app_bar.dart';
import '../widgets/password_field.dart';

/// Change Password (Security Dialogs 21b): re-authenticate with the current
/// password, then set a new one that meets the rule list.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  static final List<PasswordRule> rules = [
    PasswordRule('At least 8 characters', (v) => v.length >= 8),
    PasswordRule('Upper and lower case letters',
        (v) => v.contains(RegExp(r'[a-z]')) && v.contains(RegExp(r'[A-Z]'))),
    PasswordRule('At least one number', (v) => v.contains(RegExp(r'\d'))),
    PasswordRule(
        'At least one symbol', (v) => v.contains(RegExp(r'[^A-Za-z0-9]'))),
  ];

  /// Fingerprint / PIN check first, then the screen.
  static Future<void> open(BuildContext context) async {
    final ok = await BiometricSheet.verify(context,
        action: 'change your password');
    if (ok && context.mounted) {
      AppRoutes.push(context, const ChangePasswordScreen());
    }
  }

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  String? _currentError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_current, _new, _confirm]) {
      c.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _mismatch =>
      _confirm.text.isNotEmpty && _confirm.text != _new.text;

  bool get _valid =>
      _current.text.isNotEmpty &&
      PasswordRule.allPass(ChangePasswordScreen.rules, _new.text) &&
      _confirm.text == _new.text;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _currentError = null;
    });
    try {
      await _auth.reauthenticateWithPassword(_current.text);
      await _auth.currentUser?.updatePassword(_new.text);
      await NotificationService.add(
        type: AppNotificationType.info,
        title: 'Password changed',
        message: 'Your GemEye password was updated.',
      );
      if (!mounted) return;
      AppSnackBar.show(context,
          message: 'Password updated', type: AppSnackBarType.success);
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('Change password failed: ${e.code}');
      if (AuthService.handleSessionError(e) || !mounted) return;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          setState(() => _currentError = 'Current password is incorrect');
        case 'too-many-requests':
          AppSnackBar.show(context,
              message: 'Too many attempts. Try again later.',
              type: AppSnackBarType.error);
        case 'network-request-failed':
          AppSnackBar.show(context,
              message: 'No connection. Check your internet and try again.',
              type: AppSnackBarType.error);
        default:
          AppSnackBar.show(context,
              message: 'Could not update your password. Try again.',
              type: AppSnackBarType.error);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Change password failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Could not update your password. Try again.',
            type: AppSnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final email = _auth.currentUser?.email;
    if (email == null) return;
    try {
      await _auth.resetPassword(email);
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Password reset link sent to $email',
            type: AppSnackBarType.info);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Reset email failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Could not send the reset link. Try again.',
            type: AppSnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _new.text;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GemAppBar(
          title: 'Change Password', leading: GemAppBarLeading.back),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                    AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
                children: [
                  PasswordField(
                    controller: _current,
                    label: 'Current password',
                    hintText: 'Enter current password',
                    errorText: _currentError,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PasswordField(
                    controller: _new,
                    label: 'New password',
                    hintText: 'Create a new password',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PasswordField(
                    controller: _confirm,
                    label: 'Confirm new password',
                    hintText: 'Repeat new password',
                    errorText: _mismatch ? 'Passwords do not match' : null,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Password must have',
                            style: AppText.titleSmall.copyWith(fontSize: 12)),
                        for (final r in ChangePasswordScreen.rules) ...[
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Icon(
                                r.test(value)
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 18,
                                color: r.test(value)
                                    ? AppColors.successText
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(r.label,
                                  style: AppText.body14.copyWith(
                                      fontSize: 13,
                                      color: r.test(value)
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: const Offset(-AppSpacing.md, 0),
                      child: TextLinkButton(
                        label: 'Forgot current password?',
                        onPressed: _forgot,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: PrimaryButton(
                label: 'Update password',
                isLoading: _busy,
                onPressed: _valid ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
