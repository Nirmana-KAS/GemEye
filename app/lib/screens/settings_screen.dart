import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_config.dart';
import '../config/constants.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../services/account_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/calibration_service.dart';
import '../services/history_service.dart';
import '../services/me_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/calibration_history_sheet.dart';
import '../widgets/gem_app_bar.dart';
import '../widgets/password_field.dart';
import '../widgets/toggle_row.dart';
import 'calibration_screen.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';
import 'feedback_sheet.dart';
import 'guide_screen.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';

/// Settings (19a). Every row is wired; preferences live in
/// [SettingsService] so changes apply app-wide immediately.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  LocalProfile _profile = const LocalProfile();

  /// Server reachability (GET /health): null while checking.
  bool? _connected;
  int _latencyMs = 0;

  /// Referral threshold before the slider was dragged, to restore it when
  /// the server refuses the change.
  double _thresholdBefore = SettingsService.defaultReferralThreshold;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkServer();
    MeService.sync();
  }

  Future<void> _checkServer() async {
    setState(() => _connected = null);
    final watch = Stopwatch()..start();
    var ok = false;
    try {
      await ApiClient.instance.getJson('/health', auth: false);
      ok = true;
    } catch (e) {
      if (kDebugMode) debugPrint('Health check failed: $e');
    }
    watch.stop();
    if (!mounted) return;
    setState(() {
      _connected = ok;
      _latencyMs = watch.elapsedMilliseconds;
    });
  }

  Future<void> _saveThreshold(double v) async {
    await SettingsService.setReferralThreshold(v);
    try {
      await MeService.updateSettings(
          referralThresholdPercent: SettingsService.referralThreshold.value);
    } on ApiException catch (e) {
      await SettingsService.setReferralThreshold(_thresholdBefore);
      if (!mounted) return;
      AppSnackBar.show(context,
          message: 'Referral threshold not changed. ${e.message}',
          type: AppSnackBarType.error);
    }
  }

  Future<void> _setShowName(bool v) async {
    final before = SettingsService.showNameOnCertificates.value;
    await SettingsService.setShowNameOnCertificates(v);
    try {
      await MeService.updateSettings(showNameOnCertificates: v);
    } on ApiException catch (e) {
      await SettingsService.setShowNameOnCertificates(before);
      if (!mounted) return;
      AppSnackBar.show(context,
          message: 'Setting not changed. ${e.message}',
          type: AppSnackBarType.error);
    }
  }

  Future<void> _loadProfile() async {
    final p = await ProfileService.load();
    if (mounted) setState(() => _profile = p);
  }

  Future<void> _openProfile() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
    await _loadProfile();
  }

  // Grading

  // Data

  Future<void> _exportData() async {
    File file;
    try {
      file = await AccountService.exportCsv();
    } on StateError {
      if (mounted) {
        AppSnackBar.show(context,
            message: 'No grading data to export', type: AppSnackBarType.info);
      }
      return;
    } catch (e) {
      if (kDebugMode) debugPrint('CSV export failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Could not export your data. Try again.',
            type: AppSnackBarType.error);
      }
      return;
    }
    if (!mounted) return;
    AppSnackBar.show(context,
        message: 'Saved to Downloads', type: AppSnackBarType.success);
    try {
      await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')],
          text: 'GemEye grading data');
    } catch (e) {
      if (kDebugMode) debugPrint('CSV share failed: $e');
    }
  }

  Future<void> _clearHistory() async {
    final all = await HistoryService.load();
    if (!mounted) return;
    final count = all.length;
    final ok = await AppDialog.confirm(
      context,
      title: 'Clear all history?',
      message: 'All $count graded stone${count == 1 ? '' : 's'} and their '
          'photos will be deleted from your account. Issued certificates '
          'are not affected.',
      confirmLabel: 'Clear',
      type: AppDialogType.danger,
      icon: Icons.delete_sweep_rounded,
    );
    if (!ok) return;
    String? failure;
    for (final r in all) {
      try {
        await HistoryService.delete(r);
      } on ApiException catch (e) {
        failure = e.message;
        break;
      } catch (e) {
        if (kDebugMode) debugPrint('Clear history failed: $e');
        failure = 'Could not clear history. Try again.';
        break;
      }
    }
    if (!mounted) return;
    AppSnackBar.show(context,
        message: failure ?? 'History cleared',
        type: failure == null ? AppSnackBarType.success : AppSnackBarType.error);
  }

  // Account

  /// Signs the user in again (password or Google), so the server accepts
  /// DELETE /me. Returns false when cancelled or it failed (message shown).
  Future<bool> _reauthenticate() async {
    try {
      if (_auth.hasPassword) {
        final password = await showDialog<String>(
          context: context,
          barrierColor: AppColors.scrim,
          builder: (_) => const _PasswordPromptDialog(),
        );
        if (password == null) return false;
        await _auth.reauthenticateWithPassword(password);
      } else {
        if (!await _auth.reauthenticateWithGoogle()) return false;
      }
      // The server checks when the user last signed in (token auth_time).
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      return true;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('Re-authentication failed: ${e.code}');
      if (AuthService.handleSessionError(e) || !mounted) return false;
      final wrong = e.code == 'wrong-password' || e.code == 'invalid-credential';
      AppSnackBar.show(context,
          message: wrong
              ? 'Password is incorrect'
              : 'Could not confirm your identity. Try again.',
          type: AppSnackBarType.error);
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Re-authentication failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Could not confirm your identity. Try again.',
            type: AppSnackBarType.error);
      }
      return false;
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Delete account permanently?',
      message: 'This cannot be undone. Your profile, grading history, '
          'calibrations and photos will be removed from the server. '
          'Certificates already issued stay verifiable but lose your '
          'details.',
      confirmLabel: 'Delete',
      type: AppDialogType.danger,
      icon: Icons.person_remove_rounded,
    );
    if (!ok || !mounted) return;

    // The server needs a sign-in from the last 5 minutes. If it still says
    // reauth_required (slow dialog), ask once more.
    for (var attempt = 0;; attempt++) {
      if (!await _reauthenticate() || !mounted) return;
      try {
        await MeService.deleteAccount();
        break;
      } on ApiException catch (e) {
        if (e.code == ApiErrorCode.accountDeleted) break;
        if (e.code == ApiErrorCode.reauthRequired && attempt == 0) continue;
        if (mounted) {
          AppSnackBar.show(context,
              message: e.code == ApiErrorCode.reauthRequired
                  ? 'Please sign in again to delete your account.'
                  : e.message,
              type: AppSnackBarType.error);
        }
        return;
      }
    }

    final done =
        await AuthService.endSession(beforeSignOut: AccountService.clearLocalData);
    if (!done && mounted) {
      AppSnackBar.show(context,
          message: 'Your account was deleted. Please restart the app.',
          type: AppSnackBarType.warning);
    }
  }

  // Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GemAppBar(title: 'Settings', leading: GemAppBarLeading.back),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const _SectionLabel('PROFILE'),
            _buildProfileCard(),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionLabel('CALIBRATION'),
            _buildCalibration(),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionLabel('GRADING'),
            _buildGrading(),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionLabel('SECURITY'),
            _buildSecurity(),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionLabel('NOTIFICATIONS'),
            _buildNotifications(),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionLabel('HELP'),
            _Group(children: [
              _NavRow(
                icon: Icons.slideshow_rounded,
                label: 'View app introduction',
                onTap: () => AppRoutes.push(
                    context, const OnboardingScreen(replay: true)),
              ),
              _NavRow(
                icon: Icons.palette_rounded,
                label: 'Colour Grade Guide',
                onTap: () =>
                    AppRoutes.push(context, const GuideScreen(showBack: true)),
              ),
              _NavRow(
                icon: Icons.rate_review_rounded,
                label: 'Send feedback',
                onTap: () => FeedbackSheet.show(context),
              ),
            ]),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionLabel('CONNECTION'),
            _buildConnection(),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionLabel('DATA'),
            _Group(children: [
              _NavRow(
                icon: Icons.download_rounded,
                label: 'Export all data (CSV)',
                onTap: _exportData,
              ),
              _NavRow(
                icon: Icons.delete_sweep_rounded,
                label: 'Clear history',
                danger: true,
                onTap: _clearHistory,
              ),
            ]),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionLabel('ACCOUNT'),
            _Group(children: [
              _NavRow(
                icon: Icons.logout_rounded,
                label: 'Log out',
                onTap: () => AuthService.endSession(),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: AppSpacing.controlHeight,
              child: FilledButton.icon(
                onPressed: _deleteAccount,
                icon: const Icon(Icons.person_remove_rounded, size: 20),
                label: const Text('Delete account'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.errorText,
                  foregroundColor: AppColors.onPrimary,
                  textStyle: AppText.button,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                  'Permanently removes your profile, grading history and '
                  'certificates.',
                  style: AppText.secondary.copyWith(height: 1.45)),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset('assets/images/logo.png',
                    width: 32, height: 32),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
                '${AppConstants.appName} v${AppConstants.appVersion} · '
                'Build 1 · ${AppConstants.appYear}',
                textAlign: TextAlign.center,
                style: AppText.secondary),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final user = _auth.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : _auth.getFirstName();
    final parts = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final initials = parts.take(2).map((w) => w[0].toUpperCase()).join();
    final photo = _profile.photoPath;
    ImageProvider? image;
    if (photo != null && File(photo).existsSync()) {
      image = FileImage(File(photo));
    } else if (user?.photoURL != null) {
      image = NetworkImage(user!.photoURL!);
    }
    return _Group(children: [
      InkWell(
        onTap: _openProfile,
        highlightColor: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: image,
                child: image == null
                    ? Text(initials.isEmpty ? '?' : initials,
                        style: AppText.sectionHeader
                            .copyWith(color: AppColors.onPrimary))
                    : null,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                        '${user?.email ?? ''} · '
                        '${_profile.isCompany ? 'Company' : 'Individual'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.secondary),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 22, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildCalibration() {
    return _Group(children: [
      ValueListenableBuilder<CalibrationSession?>(
        valueListenable: CalibrationService.session,
        builder: (context, s, _) {
          final now = DateTime.now();
          final Color dot, halo;
          final String title, sub;
          if (s == null || !s.isValid) {
            (dot, halo) = (AppColors.error, AppColors.errorTint);
            title = 'Not calibrated';
            sub = s == null
                ? 'Calibrate before grading'
                : 'Last session expired · calibrate before grading';
          } else if (s.validUntil.difference(now) <
              const Duration(minutes: 30)) {
            (dot, halo) = (AppColors.warning, AppColors.warningTint);
            title = 'Calibration expires soon';
            sub = 'Less than 30 min left · recalibrate before grading';
          } else {
            (dot, halo) = (AppColors.success, AppColors.successTint);
            final until = '${s.validUntil.hour.toString().padLeft(2, '0')}:'
                '${s.validUntil.minute.toString().padLeft(2, '0')}';
            title = 'Calibrated · residual ${s.residual.toStringAsFixed(2)}';
            sub = '${s.id} · valid until $until';
          }
          return Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(color: halo, shape: BoxShape.circle),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.body14Medium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(sub, style: AppText.secondary),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      _NavRow(
        icon: Icons.refresh_rounded,
        label: 'Recalibrate',
        onTap: () => AppRoutes.push(context, const CalibrationScreen()),
      ),
      _NavRow(
        icon: Icons.history_rounded,
        label: 'Calibration History',
        onTap: () => CalibrationHistorySheet.show(
          context,
          onStart: () => AppRoutes.push(context, const CalibrationScreen()),
        ),
      ),
    ]);
  }

  Widget _buildGrading() {
    return _Group(children: [
      ValueListenableBuilder<double>(
        valueListenable: SettingsService.referralThreshold,
        builder: (context, v, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                      child: Text('Referral threshold',
                          style: AppText.body14Medium)),
                  _Pill('${v.round()}%'),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.surface,
                  trackHeight: 4,
                ),
                child: Slider(
                  value: v,
                  min: SettingsService.minReferralThreshold,
                  max: SettingsService.maxReferralThreshold,
                  divisions: (SettingsService.maxReferralThreshold -
                          SettingsService.minReferralThreshold)
                      .round(),
                  label: '${v.round()}%',
                  onChangeStart: (_) => _thresholdBefore =
                      SettingsService.referralThreshold.value,
                  onChanged: (x) =>
                      SettingsService.referralThreshold.value = x.roundToDouble(),
                  onChangeEnd: _saveThreshold,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${SettingsService.minReferralThreshold.round()}%',
                      style: AppText.caption
                          .copyWith(color: AppColors.textSecondary)),
                  Text('${SettingsService.maxReferralThreshold.round()}%',
                      style: AppText.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                  'Stones below this confidence are flagged for gemologist '
                  'review',
                  style: AppText.secondary.copyWith(height: 1.45)),
            ],
          ),
        ),
      ),
      ValueListenableBuilder<ExportFormat>(
        valueListenable: SettingsService.exportFormat,
        builder: (context, f, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Default export format',
                  style: AppText.body14Medium),
              const SizedBox(height: AppSpacing.md),
              _Segments<ExportFormat>(
                options: {for (final e in ExportFormat.values) e: e.label},
                selected: f,
                onChanged: SettingsService.setExportFormat,
              ),
            ],
          ),
        ),
      ),
      ValueListenableBuilder<bool>(
        valueListenable: SettingsService.showNameOnCertificates,
        builder: (context, on, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ToggleRow(
            title: 'Show my name/company on public certificate',
            subtitle: 'Anyone who scans the QR code can see it',
            value: on,
            onChanged: _setShowName,
          ),
        ),
      ),
      ValueListenableBuilder<bool>(
        valueListenable: SettingsService.autoSavePhotos,
        builder: (context, on, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          // TODO: copy graded photos to the gallery when this is on (the
          // setting is saved but not acted on yet).
          child: ToggleRow(
            title: 'Auto-save graded photos to gallery',
            value: on,
            onChanged: SettingsService.setAutoSavePhotos,
          ),
        ),
      ),
    ]);
  }

  Widget _buildSecurity() {
    final googleOnly = _auth.isGoogleOnly;
    return _Group(children: [
      if (googleOnly)
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_rounded,
                  size: 20, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  'You sign in with Google, so there is no GemEye password. '
                  'Manage your password in your Google account.',
                  style: AppText.secondary.copyWith(height: 1.45),
                ),
              ),
            ],
          ),
        )
      else
        _NavRow(
          icon: Icons.lock_rounded,
          label: 'Change Password',
          subtitle: 'Requires fingerprint or PIN',
          subtitleIcon: Icons.fingerprint_rounded,
          onTap: () => ChangePasswordScreen.open(context),
        ),
      _NavRow(
        icon: Icons.mail_rounded,
        label: 'Change Email',
        subtitle: 'Requires fingerprint or PIN',
        subtitleIcon: Icons.fingerprint_rounded,
        onTap: () => ChangeEmailScreen.open(context),
      ),
    ]);
  }

  Widget _buildNotifications() {
    Widget toggle(NotificationCategory c, String title) =>
        ValueListenableBuilder<bool>(
          valueListenable: SettingsService.notifierFor(c),
          builder: (context, on, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ToggleRow(
              title: title,
              value: on,
              onChanged: (v) => SettingsService.setNotify(c, v),
            ),
          ),
        );
    return _Group(children: [
      toggle(NotificationCategory.calibration, 'Calibration reminders'),
      toggle(NotificationCategory.referral, 'Referral alerts'),
      toggle(NotificationCategory.certificate, 'Certificate updates'),
    ]);
  }

  Widget _buildConnection() {
    final c = _connected;
    final label = c == null
        ? 'Server status: Checking...'
        : c
            ? 'Server status: Connected · $_latencyMs ms'
            : 'Server status: Not connected';
    return _Group(children: [
      InkWell(
        onTap: c == null ? null : _checkServer,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: c == true ? AppColors.successTint : AppColors.errorTint,
                    shape: BoxShape.circle),
                child: Icon(
                    c == true ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    size: 16,
                    color:
                        c == true ? AppColors.successText : AppColors.errorText),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: Text(label, style: AppText.body14Medium)),
              const Icon(Icons.refresh_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
      // Developer row: which server this build talks to.
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        child: Row(
          children: [
            const Icon(Icons.dns_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('API base URL', style: AppText.body14),
                  const SizedBox(height: AppSpacing.xs),
                  SelectableText(AppConfig.apiBaseUrl,
                      style: AppText.secondary),
                ],
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

// Building blocks

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.md),
      child: Text(text,
          style: AppText.titleSmall.copyWith(
              fontSize: 11,
              letterSpacing: 0.9,
              color: AppColors.textSecondary)),
    );
  }
}

/// White card with 1 px dividers between its rows.
class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? subtitle;
  final IconData? subtitleIcon;
  final bool danger;
  final VoidCallback onTap;

  const _NavRow({
    this.icon,
    required this.label,
    this.subtitle,
    this.subtitleIcon,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      highlightColor: danger ? AppColors.errorTint : AppColors.surface,
      child: Container(
        constraints: BoxConstraints(minHeight: subtitle == null ? 52 : 60),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 20,
                  color: danger ? AppColors.error : AppColors.primary),
              const SizedBox(width: AppSpacing.lg),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: danger
                          ? AppText.body14Medium
                              .copyWith(color: AppColors.errorText)
                          : AppText.body14),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        if (subtitleIcon != null) ...[
                          Icon(subtitleIcon,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Flexible(
                            child: Text(subtitle!, style: AppText.secondary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 22, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: AppText.titleSmall
              .copyWith(fontSize: 11, color: AppColors.primary)),
    );
  }
}

/// 3-option segmented control (13 px labels, 4 px gaps).
class _Segments<T> extends StatelessWidget {
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const _Segments({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.toList();
    return SizedBox(
      height: AppSpacing.controlHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Material(
                color: entries[i].key == selected
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(i == 0 ? AppRadius.lg : 0),
                  right: Radius.circular(
                      i == entries.length - 1 ? AppRadius.lg : 0),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onChanged(entries[i].key),
                  child: Center(
                    child: Text(
                      entries[i].value,
                      style: entries[i].key == selected
                          ? AppText.button.copyWith(
                              fontSize: 13, color: AppColors.onPrimary)
                          : AppText.body14Medium.copyWith(
                              fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Asks for the account password before deleting the account.
class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog();

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialog(
      title: 'Confirm your password',
      message: 'Enter your password to delete your account.',
      field: PasswordField(
        controller: _c,
        label: 'Password',
        hintText: 'Password',
        onChanged: (_) => setState(() {}),
      ),
      confirmLabel: 'Delete account',
      danger: true,
      onConfirm: _c.text.isEmpty ? null : () => Navigator.pop(context, _c.text),
    );
  }
}

/// AppDialog-styled dialog with one form field.
class _FormDialog extends StatelessWidget {
  final String title;
  final String message;
  final Widget field;
  final String confirmLabel;
  final bool danger;
  final VoidCallback? onConfirm;

  const _FormDialog({
    required this.title,
    required this.message,
    required this.field,
    required this.confirmLabel,
    this.danger = false,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      surfaceTintColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl, AppSpacing.xxxl, AppSpacing.xxl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppText.sectionHeader),
            const SizedBox(height: AppSpacing.lg),
            Text(message,
                style: AppText.body14
                    .copyWith(height: 1.5, color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            field,
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    minimumSize: const Size(
                        AppSpacing.touchTarget, AppSpacing.touchTarget),
                    textStyle: AppText.button,
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        danger ? AppColors.errorText : AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size(
                        AppSpacing.touchTarget, AppSpacing.touchTarget),
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    textStyle: AppText.button,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
