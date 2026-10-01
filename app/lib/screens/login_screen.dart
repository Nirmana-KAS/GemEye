import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../services/auth_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/input_field.dart';
import '../widgets/or_divider.dart';
import '../widgets/password_field.dart';
import 'register_screen.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Set<String> _credentialErrorCodes = {
    'invalid-credential',
    'wrong-password',
    'user-not-found',
    'invalid-email',
    'INVALID_LOGIN_CREDENTIALS',
  };

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  bool _credentialError = false;

  bool get _isBusy => _isEmailLoading || _isGoogleLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearCredentialError(String _) {
    if (_credentialError) setState(() => _credentialError = false);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null && mounted) {
        AppRoutes.pushReplacement(context, const MainShell());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Google sign-in failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Google sign-in failed. Please try again.',
            type: AppSnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppSnackBar.show(context,
          message: 'Please enter email and password',
          type: AppSnackBarType.error);
      return;
    }

    setState(() {
      _isEmailLoading = true;
      _credentialError = false;
    });
    try {
      await _authService.signInWithEmail(email, password);
      if (mounted) {
        AppRoutes.pushReplacement(context, const MainShell());
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('Email sign-in failed: ${e.code}');
      if (!mounted) return;
      if (_credentialErrorCodes.contains(e.code)) {
        setState(() => _credentialError = true);
      } else if (e.code == 'too-many-requests') {
        AppSnackBar.show(context,
            message: 'Too many attempts. Please try again later.',
            type: AppSnackBarType.error);
      } else if (e.code == 'network-request-failed') {
        AppSnackBar.show(context,
            message: 'No connection. Check your internet and try again.',
            type: AppSnackBarType.error);
      } else {
        AppSnackBar.show(context,
            message: 'Sign-in failed. Please try again.',
            type: AppSnackBarType.error);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Email sign-in failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Sign-in failed. Please try again.',
            type: AppSnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppSnackBar.show(context,
          message: 'Enter your email first', type: AppSnackBarType.info);
      return;
    }
    try {
      await _authService.resetPassword(email);
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Password reset email sent',
            type: AppSnackBarType.success);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Password reset failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Failed to send reset email. Please try again.',
            type: AppSnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.darkIcons,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(child: _buildContent()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.massive, bottom: AppSpacing.huge),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  child: Image.asset('assets/images/logo.png',
                      width: 64, height: 64),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('GemEye', style: AppText.display),
              ],
            ),
          ),
          GoogleSignInButton(
            isLoading: _isGoogleLoading,
            onPressed: _isEmailLoading ? null : _signInWithGoogle,
          ),
          const OrDivider(),
          InputField(
            label: 'Email',
            controller: _emailController,
            hintText: 'name@company.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            errorText: _credentialError ? '' : null,
            onChanged: _clearCredentialError,
          ),
          const SizedBox(height: AppSpacing.xl),
          PasswordField(
            controller: _passwordController,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            errorText:
                _credentialError ? 'Incorrect email or password' : null,
            showErrorIcon: true,
            onChanged: _clearCredentialError,
            onSubmitted: (_) => _isBusy ? null : _signInWithEmail(),
          ),
          Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.xs, bottom: AppSpacing.lg),
            child: Align(
              alignment: Alignment.centerRight,
              child: Transform.translate(
                offset: const Offset(AppSpacing.md, 0),
                child: TextLinkButton(
                  label: 'Forgot password?',
                  onPressed: _isBusy ? null : _resetPassword,
                ),
              ),
            ),
          ),
          PrimaryButton(
            label: 'Log In',
            loadingLabel: 'Logging in…',
            isLoading: _isEmailLoading,
            onPressed: _isGoogleLoading ? null : _signInWithEmail,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.xxxl, bottom: AppSpacing.huge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('New to GemEye?',
                    style: AppText.body14
                        .copyWith(color: AppColors.textSecondary)),
                TextLinkButton(
                  label: 'Register',
                  onPressed: _isBusy
                      ? null
                      : () => AppRoutes.push(context, const RegisterScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
