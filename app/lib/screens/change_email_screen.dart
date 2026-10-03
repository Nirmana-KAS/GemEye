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
import '../widgets/input_field.dart';

/// Change Email (Security Dialogs 21c): sends a verification link with
/// verifyBeforeUpdateEmail; the current email stays active until confirmed.
class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  /// Fingerprint / PIN check first, then the screen.
  static Future<void> open(BuildContext context) async {
    final ok =
        await BiometricSheet.verify(context, action: 'change your email');
    if (ok && context.mounted) {
      AppRoutes.push(context, const ChangeEmailScreen());
    }
  }

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _email = TextEditingController();
  final _auth = AuthService();
  String? _serverError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() => _serverError = null));
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  String get _value => _email.text.trim();
  bool get _bad => _value.isNotEmpty && !_emailPattern.hasMatch(_value);
  bool get _valid =>
      _value.isNotEmpty &&
      !_bad &&
      _value.toLowerCase() != (_auth.currentUser?.email ?? '').toLowerCase();

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final email = _value;
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(email);
      await NotificationService.add(
        type: AppNotificationType.info,
        title: 'Email change requested',
        message: 'Confirm the link sent to $email.',
      );
      if (!mounted) return;
      AppSnackBar.show(context,
          message: 'Verification link sent to your new email',
          type: AppSnackBarType.info);
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('Change email failed: ${e.code}');
      if (AuthService.handleSessionError(e) || !mounted) return;
      switch (e.code) {
        case 'invalid-email':
          setState(() => _serverError = 'Enter a valid email address');
        case 'email-already-in-use':
          setState(
              () => _serverError = 'An account already exists for this email');
        case 'requires-recent-login':
          AppSnackBar.show(context,
              message: 'For your security, log out and log in again first.',
              type: AppSnackBarType.warning);
        case 'network-request-failed':
          AppSnackBar.show(context,
              message: 'No connection. Check your internet and try again.',
              type: AppSnackBarType.error);
        default:
          AppSnackBar.show(context,
              message: 'Could not send the verification link. Try again.',
              type: AppSnackBarType.error);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Change email failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Could not send the verification link. Try again.',
            type: AppSnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _auth.currentUser?.email ?? '-';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GemAppBar(
          title: 'Change Email', leading: GemAppBarLeading.back),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                    AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
                children: [
                  const FieldLabel(text: 'Current email'),
                  const SizedBox(height: AppSpacing.md),
                  LockedValue(value: current),
                  const SizedBox(height: AppSpacing.xl),
                  InputField(
                    label: 'New email',
                    controller: _email,
                    hintText: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.done,
                    errorText: _serverError ??
                        (_bad ? 'Enter a valid email address' : null),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.mark_email_unread_rounded,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Text(
                            "We'll send a verification link to the new "
                            'address. Your current email stays active until '
                            'you confirm it.',
                            style: AppText.body14.copyWith(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ],
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
                label: 'Send verification link',
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

/// Read-only value in a Primary Surface field with a lock icon.
class LockedValue extends StatelessWidget {
  final String value;

  const LockedValue({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body14.copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.lock_rounded, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
