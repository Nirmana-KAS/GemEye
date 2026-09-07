import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../services/auth_service.dart';
import '../config/routes.dart';
import '../screens/login_screen.dart';
import '../screens/comparison_screen.dart';
import '../screens/capture_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/feedback_sheet.dart';
import '../screens/profile_screen.dart';

class GemEyeSideDrawer extends StatelessWidget {
  final void Function(int index)? onTabSwitch;

  const GemEyeSideDrawer({super.key, this.onTabSwitch});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                AppRoutes.push(context, const ProfileScreen());
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: GemEyeColors.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Text(
                              authService.getFirstName()[0].toUpperCase(),
                              style: const TextStyle(
                                fontFamily: GemEyeFonts.heading,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.displayName ?? authService.getFirstName(),
                      style: const TextStyle(
                        fontFamily: GemEyeFonts.heading,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontFamily: GemEyeFonts.body,
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(context, Icons.home_rounded, 'Home', () {
                    Navigator.pop(context);
                    onTabSwitch?.call(0);
                  }),
                  _buildMenuItem(
                      context, Icons.camera_alt_rounded, 'Grade a Stone', () {
                    Navigator.pop(context);
                    AppRoutes.push(context, const CaptureScreen());
                  }),
                  _buildMenuItem(
                      context, Icons.history_rounded, 'Grading History', () {
                    Navigator.pop(context);
                    onTabSwitch?.call(2);
                  }),
                  _buildMenuItem(
                      context, Icons.palette_rounded, 'Colour Grade Guide', () {
                    Navigator.pop(context);
                    onTabSwitch?.call(3);
                  }),
                  _buildMenuItem(
                      context, Icons.compare_rounded, 'Stone Comparison', () {
                    Navigator.pop(context);
                    AppRoutes.push(context, const ComparisonScreen());
                  }),
                  _buildMenuItem(
                      context, Icons.settings_rounded, 'Settings', () {
                    Navigator.pop(context);
                    AppRoutes.push(context, const SettingsScreen());
                  }),
                  const Divider(height: 1),
                  _buildMenuItem(
                      context, Icons.feedback_rounded, 'Feedback', () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (ctx) => const FeedbackSheet(),
                    );
                  }),
                  _buildMenuItem(
                      context, Icons.lock_rounded, 'Privacy Policy', () {
                    Navigator.pop(context);
                    AppRoutes.push(context, const PrivacyScreen());
                  }),
                  _buildMenuItem(context, Icons.info_rounded, 'About', () {
                    Navigator.pop(context);
                    AppRoutes.push(context, const AboutScreen());
                  }),
                  const Divider(height: 1),
                  _buildMenuItem(
                    context,
                    Icons.logout_rounded,
                    'Logout',
                    () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text(
                            'Logout',
                            style: TextStyle(
                              fontFamily: GemEyeFonts.heading,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          content: const Text(
                            'Are you sure you want to logout?',
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
                                Navigator.pop(ctx);
                                await authService.signOut();
                                if (context.mounted) {
                                  AppRoutes.pushReplacement(
                                      context, const LoginScreen());
                                }
                              },
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: GemEyeColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '${AppConstants.appName} v${AppConstants.appVersion} · ${AppConstants.appYear}',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 11,
                  color: GemEyeColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon,
          size: 22,
          color:
              isDestructive ? GemEyeColors.error : GemEyeColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: GemEyeFonts.body,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDestructive ? GemEyeColors.error : GemEyeColors.textPrimary,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }
}
