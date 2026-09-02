import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../services/auth_service.dart';
import '../config/routes.dart';
import '../screens/login_screen.dart';
import '../screens/comparison_screen.dart';

class GemEyeSideDrawer extends StatelessWidget {
  const GemEyeSideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
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
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(context, Icons.home_rounded, 'Home',
                      () => Navigator.pop(context)),
                  _buildMenuItem(context, Icons.camera_alt_rounded,
                      'Grade a Stone', () => Navigator.pop(context)),
                  _buildMenuItem(context, Icons.history_rounded,
                      'Grading History', () => Navigator.pop(context)),
                  _buildMenuItem(context, Icons.palette_rounded,
                      'Colour Grade Guide', () => Navigator.pop(context)),
                  _buildMenuItem(context, Icons.compare_rounded,
                      'Stone Comparison', () {
                    Navigator.pop(context);
                    AppRoutes.push(context, const ComparisonScreen());
                  }),
                  _buildMenuItem(context, Icons.settings_rounded, 'Settings',
                      () => Navigator.pop(context)),
                  const Divider(height: 1),
                  _buildMenuItem(context, Icons.feedback_rounded, 'Feedback',
                      () => Navigator.pop(context)),
                  _buildMenuItem(context, Icons.lock_rounded, 'Privacy Policy',
                      () => Navigator.pop(context)),
                  _buildMenuItem(context, Icons.info_rounded, 'About',
                      () => Navigator.pop(context)),
                  const Divider(height: 1),
                  _buildMenuItem(context, Icons.logout_rounded, 'Logout',
                    () async {
                      Navigator.pop(context);
                      await authService.signOut();
                      if (context.mounted) {
                        AppRoutes.pushReplacement(
                            context, const LoginScreen());
                      }
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
