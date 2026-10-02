import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../services/auth_service.dart';
import '../config/routes.dart';
import '../screens/onboarding_screen.dart';
import '../screens/comparison_screen.dart';
import '../screens/calibration_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/feedback_sheet.dart';
import '../screens/profile_screen.dart';

/// Right-side navigation drawer opened from the Home avatar.
class GemEyeSideDrawer extends StatelessWidget {
  final void Function(int index)? onTabSwitch;

  /// MainShell tab currently shown (0 Home, 2 History, 3 Guide), used to
  /// highlight the current page.
  final int currentIndex;

  const GemEyeSideDrawer({
    super.key,
    this.onTabSwitch,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    void closeThen(VoidCallback action) {
      Navigator.pop(context);
      action();
    }

    // Separate screens open over the drawer, so back returns to it.
    void push(Widget screen) => AppRoutes.push(context, screen);
    // Tab items close the drawer, then switch the MainShell tab.
    void tab(int index) => closeThen(() => onTabSwitch?.call(index));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.lightIcons,
      child: Drawer(
        width: 296,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.horizontal(left: Radius.circular(AppRadius.xxl)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _Header(
                onClose: () => Navigator.pop(context),
                onProfile: () {
                  push(const ProfileScreen());
                }),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: 10),
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: currentIndex == 0,
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.center_focus_strong_rounded,
                    label: 'Grade a Stone',
                    onTap: () => tab(1),
                  ),
                  _DrawerItem(
                    icon: Icons.palette_rounded,
                    label: 'Calibration',
                    onTap: () => push(const CalibrationScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.history_rounded,
                    label: 'Grading History',
                    selected: currentIndex == 2,
                    onTap: () => tab(2),
                  ),
                  _DrawerItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Colour Grade Guide',
                    selected: currentIndex == 3,
                    onTap: () => tab(3),
                  ),
                  _DrawerItem(
                    icon: Icons.compare_rounded,
                    label: 'Stone Comparison',
                    onTap: () => push(const ComparisonScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () => push(const SettingsScreen()),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                    child: Divider(),
                  ),
                  _DrawerItem(
                    icon: Icons.rate_review_rounded,
                    label: 'Feedback',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppRadius.xxl + 4)),
                        ),
                        builder: (ctx) => const FeedbackSheet(),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.privacy_tip_rounded,
                    label: 'Privacy Policy',
                    onTap: () => push(const PrivacyScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.info_rounded,
                    label: 'About',
                    onTap: () => push(const AboutScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.slideshow_rounded,
                    label: 'View app introduction',
                    onTap: () => push(const OnboardingScreen(replay: true)),
                  ),
                ],
              ),
            ),
            _Footer(onLogout: () => closeThen(_confirmLogout)),
          ],
        ),
      ),
    );
  }

  static void _confirmLogout() {
    final ctx = AppRoutes.navigatorKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: const Text('Logout', style: AppText.sectionHeader),
        content: Text('Are you sure you want to logout?',
            style: AppText.body14.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: AppText.button.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => AuthService.endSession(),
            child: Text('Logout',
                style: AppText.button.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onProfile;

  const _Header({required this.onClose, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : authService.getFirstName();
    final parts = name.split(RegExp(r'\s+'));
    final initials = (parts.length > 1
            ? '${parts.first[0]}${parts.last[0]}'
            : name.substring(0, name.length >= 2 ? 2 : 1))
        .toUpperCase();
    final photoUrl = user?.photoURL;

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        MediaQuery.of(context).padding.top + AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text('GemEye',
                    style: AppText.display
                        .copyWith(height: 1, color: AppColors.onPrimary)),
              ),
              IconButton(
                tooltip: 'Close menu',
                onPressed: onClose,
                color: AppColors.onPrimary,
                style: IconButton.styleFrom(
                    highlightColor: AppColors.primaryLight),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            highlightColor: AppColors.primaryLight,
            splashColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(initials,
                            style: AppText.titleSmall
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
                            style: AppText.titleSmall
                                .copyWith(color: AppColors.onPrimary)),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.secondary
                                .copyWith(color: AppColors.onPrimary)),
                        // TODO(F2): show "Role · Company" once the profile
                        // is persisted.
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            highlightColor: AppColors.surface,
            splashColor: Colors.transparent,
            child: SizedBox(
              height: AppSpacing.touchTarget,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  children: [
                    Icon(icon,
                        size: 22,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: selected
                            ? AppText.titleSmall
                                .copyWith(color: AppColors.primary)
                            : AppText.body14Medium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onLogout;

  const _Footer({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                highlightColor: AppColors.errorTint,
                splashColor: Colors.transparent,
                child: SizedBox(
                  height: AppSpacing.touchTarget,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded,
                            size: 22, color: AppColors.error),
                        const SizedBox(width: 14),
                        Text('Logout',
                            style: AppText.body14Medium
                                .copyWith(color: AppColors.error)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // TODO: append server status (e.g. "Server connected") once the
            // backend health check exists.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text('App v${AppConstants.appVersion}',
                  style: AppText.caption),
            ),
          ],
        ),
      ),
    );
  }
}
