import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/constants.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/gem_app_bar.dart';
import 'feedback_sheet.dart';
import 'privacy_screen.dart';

/// About (22a): app, developer, special thanks, feedback and privacy links.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Optional images; each falls back when the file is not bundled.
  static const String _developerPhoto = 'assets/images/about/developer.jpg';
  static const String _nsbmLogo = 'assets/images/about/nsbm.png';
  static const String _oravaLogo = 'assets/images/about/orava.png';

  Future<void> _launch(BuildContext context, String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('launch returned false');
    } catch (e) {
      if (kDebugMode) debugPrint('Link open failed: $e');
      if (context.mounted) {
        AppSnackBar.show(context,
            message: 'Could not open the link', type: AppSnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final links = <(IconData, String, String)>[
      if (AppConstants.linkedInUrl.isNotEmpty)
        (Icons.business_center_rounded, 'LinkedIn', AppConstants.linkedInUrl),
      if (AppConstants.githubUrl.isNotEmpty)
        (Icons.code_rounded, 'GitHub', AppConstants.githubUrl),
      if (AppConstants.emailAddress.isNotEmpty)
        (Icons.mail_rounded, 'Email', 'mailto:${AppConstants.emailAddress}'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GemAppBar(title: 'About', leading: GemAppBarLeading.back),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, 28, AppSpacing.xl, AppSpacing.xl),
          children: [
            // App
            Center(
              child: Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Image.asset('assets/images/logo.png'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(AppConstants.appName,
                textAlign: TextAlign.center,
                style: AppText.display.copyWith(fontSize: 26)),
            const SizedBox(height: AppSpacing.md),
            Text('AI colour grading for blue sapphires',
                textAlign: TextAlign.center,
                style: AppText.body14
                    .copyWith(height: 1.45, color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('v${AppConstants.appVersion} · Build 1',
                    style: AppText.monoValue.copyWith(
                        fontSize: 11, color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Developer
            const _SectionLabel('DEVELOPER'),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          _developerPhoto,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            alignment: Alignment.center,
                            color: AppColors.primaryLight,
                            child: Text('NK',
                                style: AppText.sectionHeader.copyWith(
                                    fontSize: 20,
                                    color: AppColors.onPrimary)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(AppConstants.developerName,
                                style: AppText.sectionHeader),
                            const SizedBox(height: AppSpacing.xs),
                            Text('BSc (Hons) Computer Science',
                                style: AppText.body14.copyWith(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (links.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        for (final (i, l) in links.indexed) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _launch(context, l.$3),
                              icon: Icon(l.$1, size: 18),
                              label: Text(l.$2,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                minimumSize:
                                    const Size(0, AppSpacing.controlHeight),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md),
                                textStyle:
                                    AppText.button.copyWith(fontSize: 12),
                                side: const BorderSide(
                                    color: AppColors.primary, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Special thanks (no team member names until they are confirmed)
            const _SectionLabel('SPECIAL THANKS'),
            const _OrgCard(
              logo: _nsbmLogo,
              fallbackIcon: Icons.school_rounded,
              name: 'NSBM Green University',
              role: 'Academic supervision',
            ),
            const SizedBox(height: AppSpacing.md),
            const _OrgCard(
              logo: _oravaLogo,
              fallbackIcon: Icons.diamond_rounded,
              name: 'Orava (Pvt) Ltd.',
              role: 'Industry partner · gemstone expertise',
            ),
            const SizedBox(height: AppSpacing.xl),

            _LinkRow(
              icon: Icons.rate_review_rounded,
              label: 'Send feedback',
              onTap: () => FeedbackSheet.show(context),
            ),
            const SizedBox(height: AppSpacing.md),
            _LinkRow(
              icon: Icons.policy_rounded,
              label: 'Privacy Policy',
              onTap: () => AppRoutes.push(context, const PrivacyScreen()),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Made in Sri Lanka · © ${AppConstants.appYear}',
                textAlign: TextAlign.center, style: AppText.secondary),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

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

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _OrgCard extends StatelessWidget {
  final String logo;
  final IconData fallbackIcon;
  final String name;
  final String role;

  const _OrgCard({
    required this.logo,
    required this.fallbackIcon,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.asset(
              logo,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: AppColors.surface,
                child: Icon(fallbackIcon, size: 24, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(role, style: AppText.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        highlightColor: AppColors.surface,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: Text(label, style: AppText.body14Medium)),
              const Icon(Icons.chevron_right_rounded,
                  size: 22, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
