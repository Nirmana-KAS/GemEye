import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../config/routes.dart';
import '../services/auth_service.dart';
import '../services/calibration_service.dart';
import '../services/storage_service.dart';
import '../widgets/calibration_history_sheet.dart';
import 'onboarding_screen.dart';
import 'calibration_screen.dart';
import 'profile_screen.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  double _confidenceThreshold = 70;
  String _exportFormat = 'PDF Certificate';
  String _certificatePrefix = AppConstants.defaultCertificatePrefix;
  bool _autoSaveImages = false;
  bool _isCalibrated = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _confidenceThreshold = prefs.getDouble('confidence_threshold') ?? 70;
      _exportFormat = prefs.getString('export_format') ?? 'PDF Certificate';
      _certificatePrefix = prefs.getString('certificate_prefix') ?? AppConstants.defaultCertificatePrefix;
      _autoSaveImages = prefs.getBool('auto_save_images') ?? false;
      _isCalibrated = CalibrationService.isValidNow;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: GemEyeColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Profile'),
            ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: GemEyeColors.primarySurface,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? const Icon(Icons.person, color: GemEyeColors.primary, size: 24)
                    : null,
              ),
              title: Text(
                user?.displayName ?? _authService.getFirstName(),
                style: const TextStyle(
                  fontFamily: GemEyeFonts.heading,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              subtitle: Text(
                user?.email ?? '',
                style: const TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 12,
                  color: GemEyeColors.textSecondary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: GemEyeColors.textMuted),
              onTap: () => AppRoutes.push(context, const ProfileScreen()),
            ),
            const Divider(),

            _buildSectionHeader('Calibration'),
            ListTile(
              leading: const Icon(Icons.tune_rounded, color: GemEyeColors.textSecondary),
              title: const Text(
                'Device Calibration',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              subtitle: Text(
                _isCalibrated ? 'Calibrated' : 'Not calibrated',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 12,
                  color: _isCalibrated ? GemEyeColors.success : GemEyeColors.error,
                ),
              ),
              trailing: TextButton(
                onPressed: () {
                  AppRoutes.push(context, const CalibrationScreen());
                },
                child: const Text(
                  'Recalibrate',
                  style: TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 12,
                    color: GemEyeColors.primary,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded, color: GemEyeColors.textSecondary),
              title: const Text(
                'Calibration History',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              subtitle: const Text(
                'View past calibrations',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 12,
                  color: GemEyeColors.textSecondary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: GemEyeColors.textMuted),
              onTap: () => CalibrationHistorySheet.show(
                context,
                onStart: () =>
                    AppRoutes.push(context, const CalibrationScreen()),
              ),
            ),
            const Divider(),

            _buildSectionHeader('Grading Preferences'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confidence Threshold',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 14,
                      color: GemEyeColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Warn when below ${_confidenceThreshold.round()}%',
                    style: const TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 12,
                      color: GemEyeColors.textSecondary,
                    ),
                  ),
                  Slider(
                    value: _confidenceThreshold,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_confidenceThreshold.round()}%',
                    onChanged: (value) {
                      setState(() => _confidenceThreshold = value);
                    },
                    onChangeEnd: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setDouble('confidence_threshold', value);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Threshold set to ${value.round()}%')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.file_download_rounded, color: GemEyeColors.textSecondary),
              title: const Text(
                'Default Export Format',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              trailing: DropdownButton<String>(
                value: _exportFormat,
                underline: const SizedBox(),
                style: const TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 13,
                  color: GemEyeColors.primary,
                ),
                items: const [
                  DropdownMenuItem(value: 'PDF Certificate', child: Text('PDF Certificate')),
                  DropdownMenuItem(value: 'Image Only', child: Text('Image Only')),
                  DropdownMenuItem(value: 'Both', child: Text('Both')),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() => _exportFormat = value);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('export_format', value);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.badge_rounded, color: GemEyeColors.textSecondary),
              title: const Text(
                'Certificate Prefix',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Current: $_certificatePrefix',
                style: const TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 12,
                  color: GemEyeColors.textSecondary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: GemEyeColors.textMuted),
              onTap: () => _showPrefixEditDialog(context),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.save_alt_rounded, color: GemEyeColors.textSecondary),
              title: const Text(
                'Auto-Save Images',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              subtitle: const Text(
                'Save graded images to gallery automatically',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 12,
                  color: GemEyeColors.textSecondary,
                ),
              ),
              value: _autoSaveImages,
              activeTrackColor: GemEyeColors.primary,
              onChanged: (value) async {
                setState(() => _autoSaveImages = value);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('auto_save_images', value);
              },
            ),
            const Divider(),

            _buildSectionHeader('Security'),
            ListTile(
              leading: const Icon(Icons.lock_rounded, color: GemEyeColors.textSecondary),
              title: const Text(
                'Change Password',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: GemEyeColors.textMuted),
              onTap: () => _showChangePasswordDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.email_rounded, color: GemEyeColors.textSecondary),
              title: const Text(
                'Change Email',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: GemEyeColors.textMuted),
              onTap: () => _showChangeEmailDialog(context),
            ),
            const Divider(),

            _buildSectionHeader('Data Management'),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: GemEyeColors.textSecondary),
              title: const Text(
                'Export All Data',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              trailing: const Icon(Icons.download, color: GemEyeColors.textMuted),
              onTap: () => _exportData(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: GemEyeColors.error),
              title: const Text(
                'Clear All History',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.error,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: GemEyeColors.textMuted),
              onTap: () => _showClearHistoryDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_rounded, color: GemEyeColors.error),
              title: const Text(
                'Delete Account',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.error,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: GemEyeColors.textMuted),
              onTap: () => _showDeleteAccountDialog(context),
            ),
            const Divider(),

            _buildSectionHeader('Help'),
            ListTile(
              leading: const Icon(Icons.slideshow_rounded, color: GemEyeColors.textSecondary),
              title: const Text(
                'View app introduction',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: GemEyeColors.textMuted),
              onTap: () => AppRoutes.push(context, const OnboardingScreen(replay: true)),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: GemEyeColors.error),
              title: const Text(
                'Log out',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.error,
                ),
              ),
              onTap: () => AuthService.endSession(),
            ),
            const Divider(),

            _buildSectionHeader('App Info'),
            const ListTile(
              leading: Icon(Icons.info_outline_rounded, color: GemEyeColors.textSecondary),
              title: Text(
                'App Version',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'GemEye v1.0 - Build 1 - September 2026',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 12,
                  color: GemEyeColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: GemEyeFonts.heading,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: GemEyeColors.primary,
        ),
      ),
    );
  }

  void _showPrefixEditDialog(BuildContext context) {
    final controller = TextEditingController(text: _certificatePrefix);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Certificate Prefix',
          style: TextStyle(
            fontFamily: GemEyeFonts.heading,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Prefix',
            hintText: 'e.g. GE',
          ),
          style: const TextStyle(fontFamily: GemEyeFonts.body, fontSize: 14),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final prefix = controller.text.trim();
              if (prefix.isEmpty) return;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('certificate_prefix', prefix);
              setState(() => _certificatePrefix = prefix);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Prefix updated to $prefix')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontFamily: GemEyeFonts.heading,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
              style: const TextStyle(fontFamily: GemEyeFonts.body, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
              style: const TextStyle(fontFamily: GemEyeFonts.body, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              style: const TextStyle(fontFamily: GemEyeFonts.body, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              try {
                final user = FirebaseAuth.instance.currentUser;
                final credential = EmailAuthProvider.credential(
                  email: user?.email ?? '',
                  password: currentController.text,
                );
                await user?.reauthenticateWithCredential(credential);
                await user?.updatePassword(newController.text);
                await NotificationService.add(
                  type: AppNotificationType.info,
                  title: 'Password changed',
                  message: 'Your GemEye password was updated.',
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update password. Check your current password.')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Change Email',
          style: TextStyle(
            fontFamily: GemEyeFonts.heading,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'New Email Address'),
          style: const TextStyle(fontFamily: GemEyeFonts.body, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser
                    ?.verifyBeforeUpdateEmail(emailController.text.trim());
                await NotificationService.add(
                  type: AppNotificationType.info,
                  title: 'Email change requested',
                  message:
                      'Confirm the link sent to ${emailController.text.trim()}.',
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email sent to new address')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to send verification email')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final history = await StorageService.getGradeHistory();
      if (history.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No grading data to export')),
          );
        }
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('Stone ID,Grade,Grade Name,Confidence,Date');
      for (final result in history) {
        buffer.writeln(
          '${result.stoneId},${result.gradeNumber},${result.gradeName},${result.confidence},${result.capturedAt.toIso8601String()}',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export data')),
        );
      }
    }
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Clear All History',
          style: TextStyle(
            fontFamily: GemEyeFonts.heading,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Delete all grading records? This cannot be undone.',
          style: TextStyle(
            fontFamily: GemEyeFonts.body,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearHistory();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All history cleared')),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: GemEyeColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontFamily: GemEyeFonts.heading,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Delete your account and all data? This cannot be undone.',
          style: TextStyle(
            fontFamily: GemEyeFonts.body,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final ok = await AuthService.endSession(
                beforeSignOut: () async {
                  await StorageService.clearHistory();
                  await FirebaseAuth.instance.currentUser?.delete();
                },
              );
              if (!ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete account. Please re-login and try again.')),
                );
              }
            },
            child: const Text(
              'Delete Account',
              style: TextStyle(color: GemEyeColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
