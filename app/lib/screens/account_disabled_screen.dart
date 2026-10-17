import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/full_screen_message.dart';

/// Shown when an admin disabled the account (401/403 account_disabled from
/// the API, or Firebase user-disabled). No retry: the only ways out are
/// contacting support and signing out.
class AccountDisabledScreen extends StatelessWidget {
  /// Signs out and opens Login (AuthService.endSession).
  final Future<void> Function() onSignOut;

  const AccountDisabledScreen({super.key, required this.onSignOut});

  static const String title = 'Account disabled';
  static const String message = 'Account disabled. Contact support.';

  static Uri supportUri() => Uri(
        scheme: 'mailto',
        path: AppConstants.supportEmail,
        query: 'subject=${Uri.encodeComponent('GemEye account disabled')}',
      );

  Future<void> _contactSupport(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(supportUri());
    } catch (e) {
      if (kDebugMode) debugPrint('Support email not opened: $e');
    }
    if (!opened && context.mounted) {
      AppSnackBar.show(context,
          message: 'Email us at ${AppConstants.supportEmail}',
          type: AppSnackBarType.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: FullScreenMessage(
        icon: Icons.person_off_rounded,
        iconColor: AppColors.errorText,
        iconTint: AppColors.errorTint,
        title: title,
        message: message,
        actions: [
          PrimaryButton(
            label: 'Email support',
            icon: Icons.mail_rounded,
            onPressed: () => _contactSupport(context),
          ),
          SecondaryButton(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}
