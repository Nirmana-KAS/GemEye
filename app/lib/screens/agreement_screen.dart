import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_checkbox.dart';
import '../widgets/gem_app_bar.dart';
import '../widgets/policy_markdown.dart';
import 'login_screen.dart';

class AgreementScreen extends StatefulWidget {
  const AgreementScreen({super.key});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  bool _accepted = false;

  static const List<String> _summaryPoints = [
    'Your data is used only for colour grading.',
    'Images are stored securely and never shared.',
    'Delete your data anytime in Settings.',
    'Images are never sold or used outside the app.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GemAppBar(title: 'Before you start'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.screen,
            AppSpacing.screen, AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummary(),
            const SizedBox(height: AppSpacing.xxxl),
            const PolicyMarkdown(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your data, in short', style: AppText.sectionHeader),
          for (final point in _summaryPoints) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(point, style: AppText.body14)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    const linkStyle = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w500,
    );
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg,
              AppSpacing.screen, AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppCheckbox(
                value: _accepted,
                onChanged: (value) => setState(() => _accepted = value),
                label: const Text.rich(TextSpan(
                  text: 'I have read and agree to the ',
                  children: [
                    TextSpan(text: 'Privacy Policy', style: linkStyle),
                    TextSpan(text: ' and '),
                    TextSpan(text: 'Terms of Use', style: linkStyle),
                  ],
                )),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Accept & Continue',
                onPressed: _accepted
                    ? () =>
                        AppRoutes.pushReplacement(context, const LoginScreen())
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
