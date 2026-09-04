import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../services/auth_service.dart';
import '../config/routes.dart';
import '../screens/login_screen.dart';
import '../screens/comparison_screen.dart';
import '../screens/capture_screen.dart';

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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.white,
                          appBar: AppBar(
                            title: const Text(
                              'Settings',
                              style: TextStyle(
                                fontFamily: GemEyeFonts.heading,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: GemEyeColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          body: const Center(
                            child: Text(
                              'Coming Soon',
                              style: TextStyle(
                                fontFamily: GemEyeFonts.body,
                                fontSize: 18,
                                color: GemEyeColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const Divider(height: 1),
                  _buildMenuItem(
                      context, Icons.feedback_rounded, 'Feedback', () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Send Feedback',
                              style: TextStyle(
                                fontFamily: GemEyeFonts.heading,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: GemEyeColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Coming Soon',
                              style: TextStyle(
                                fontFamily: GemEyeFonts.body,
                                fontSize: 14,
                                color: GemEyeColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  }),
                  _buildMenuItem(
                      context, Icons.lock_rounded, 'Privacy Policy', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.white,
                          appBar: AppBar(
                            title: const Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontFamily: GemEyeFonts.heading,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: GemEyeColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          body: const SingleChildScrollView(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'GemEye Privacy Policy\n\n'
                              'Last updated: September 2026\n\n'
                              'GemEye collects and processes gemstone images solely for colour grading purposes. '
                              'Images are processed on-device or via secure cloud endpoints. '
                              'No personal data is shared with third parties.\n\n'
                              'Data collected:\n'
                              '- User account information (name, email)\n'
                              '- Gemstone images for grading\n'
                              '- Grading history and certificates\n\n'
                              'Data storage:\n'
                              '- Account data stored securely via Firebase Authentication\n'
                              '- Grading history stored locally on device\n'
                              '- Images processed and discarded after grading\n\n'
                              'Contact: shehannirmana.orava@gmail.com',
                              style: TextStyle(
                                fontFamily: GemEyeFonts.body,
                                fontSize: 14,
                                height: 1.6,
                                color: GemEyeColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  _buildMenuItem(context, Icons.info_rounded, 'About', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.white,
                          appBar: AppBar(
                            title: const Text(
                              'About',
                              style: TextStyle(
                                fontFamily: GemEyeFonts.heading,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: GemEyeColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          body: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                Image.asset('assets/images/logo.png',
                                    width: 80, height: 80),
                                const SizedBox(height: 16),
                                const Text(
                                  'GemEye',
                                  style: TextStyle(
                                    fontFamily: GemEyeFonts.heading,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: GemEyeColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'v${AppConstants.appVersion} · ${AppConstants.appYear}',
                                  style: TextStyle(
                                    fontFamily: GemEyeFonts.body,
                                    fontSize: 14,
                                    color: GemEyeColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Automated Blue Sapphire Colour Grading',
                                  style: TextStyle(
                                    fontFamily: GemEyeFonts.body,
                                    fontSize: 14,
                                    color: GemEyeColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 16),
                                const Text(
                                  'Developer',
                                  style: TextStyle(
                                    fontFamily: GemEyeFonts.heading,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: GemEyeColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Nirmana K.A.S.',
                                  style: TextStyle(
                                    fontFamily: GemEyeFonts.body,
                                    fontSize: 14,
                                    color: GemEyeColors.textPrimary,
                                  ),
                                ),
                                const Text(
                                  'BSc (Hons) Computer Science',
                                  style: TextStyle(
                                    fontFamily: GemEyeFonts.body,
                                    fontSize: 12,
                                    color: GemEyeColors.textSecondary,
                                  ),
                                ),
                                const Text(
                                  'NSBM Green University, Sri Lanka',
                                  style: TextStyle(
                                    fontFamily: GemEyeFonts.body,
                                    fontSize: 12,
                                    color: GemEyeColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 16),
                                const Text(
                                  'Powered by',
                                  style: TextStyle(
                                    fontFamily: GemEyeFonts.heading,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: GemEyeColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'EfficientNet-B0 + Random Forest Ensemble',
                                  style: TextStyle(
                                    fontFamily: GemEyeFonts.body,
                                    fontSize: 12,
                                    color: GemEyeColors.textSecondary,
                                  ),
                                ),
                                const Text(
                                  'GEMCLOUD 7-Grade Colour Intensity Standard',
                                  style: TextStyle(
                                    fontFamily: GemEyeFonts.body,
                                    fontSize: 12,
                                    color: GemEyeColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
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
