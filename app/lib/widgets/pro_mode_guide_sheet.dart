import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'app_buttons.dart';

/// Bottom sheet explaining how to capture in the phone camera's Pro mode.
class ProModeGuideSheet extends StatelessWidget {
  const ProModeGuideSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      barrierColor: AppColors.scrim,
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.logo)),
      ),
      builder: (_) => const ProModeGuideSheet(),
    );
  }

  static const List<(String, String, IconData)> _steps = [
    (
      'Open camera → Pro / Manual mode',
      'Swipe the mode bar to Pro or Manual',
      Icons.photo_camera_outlined
    ),
    (
      'Set WB to Daylight',
      '≈5000-5500 K · keep it locked',
      Icons.wb_sunny_outlined
    ),
    (
      'Set focus on the stone',
      'Use manual focus (MF) until edges are sharp',
      Icons.center_focus_strong_outlined
    ),
    (
      'Lock exposure on the stone',
      'Tap and hold the stone to lock AE',
      Icons.exposure_outlined
    ),
    (
      'Take photo, then return to GemEye',
      'Tap Import from Gallery',
      Icons.photo_library_outlined
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Set up Pro mode', style: AppText.sectionHeader),
            const SizedBox(height: AppSpacing.xs),
            Text("In your phone's own camera app",
                style: AppText.secondary
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            for (var i = 0; i < _steps.length; i++)
              _buildStep(i, _steps[i], last: i == _steps.length - 1),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.dataset_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      "These are the same settings used to build GemEye's dataset.",
                      style: AppText.body14.copyWith(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Got it',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int i, (String, String, IconData) step,
      {required bool last}) {
    final (title, sub, icon) = step;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: Text('${i + 1}',
                      style: AppText.button.copyWith(
                          fontSize: 12, color: AppColors.onPrimary)),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(minHeight: 12),
                      margin:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: AppSpacing.xl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppText.titleSmall.copyWith(height: 1.35)),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(sub,
                            style: AppText.secondary.copyWith(
                                height: 1.4, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, size: 22, color: AppColors.primary),
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
