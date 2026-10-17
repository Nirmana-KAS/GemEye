import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Full-screen blocking message (Account disabled, Maintenance): icon chip,
/// title, message and the buttons below. White background, no app bar.
class FullScreenMessage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconTint;
  final String title;
  final String message;
  final List<Widget> actions;

  const FullScreenMessage({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconTint,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen, vertical: AppSpacing.huge),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.huge * 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                          color: iconTint, shape: BoxShape.circle),
                      child: Icon(icon, size: 36, color: iconColor),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text(title,
                      textAlign: TextAlign.center, style: AppText.screenTitle),
                  const SizedBox(height: AppSpacing.md),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: AppText.body14
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.huge),
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.lg),
                    actions[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
