import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/gem_app_bar.dart';
import '../widgets/policy_markdown.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      appBar: GemAppBar(
        title: 'Privacy Policy',
        leading: GemAppBarLeading.back,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.screen,
              AppSpacing.screen, AppSpacing.huge),
          child: PolicyMarkdown(),
        ),
      ),
    );
  }
}
