import 'dart:io';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/grading_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_dialog.dart';
import '../widgets/card_container.dart';
import '../widgets/gem_app_bar.dart';
import 'capture_screen.dart';

/// Result template when the photo fails the stone / colour / recognition
/// checks. No grade is shown.
// TODO(backend): opened from ProcessingScreen when the server response
// carries a rejection status (see RejectionReason.fromStatus).
class NotAcceptedScreen extends StatelessWidget {
  final RejectionReason reason;
  final String imagePath;
  final String? sessionId;

  /// Measured hue in degrees, shown for [RejectionReason.notBlue].
  final double? measuredHue;

  const NotAcceptedScreen({
    super.key,
    required this.reason,
    required this.imagePath,
    this.sessionId,
    this.measuredHue,
  });

  (IconData, String, String) get _content => switch (reason) {
        RejectionReason.noStone => (
            Icons.image_search_rounded,
            'No gemstone detected',
            "We couldn't find a stone in this photo. Centre the stone on the "
                'white tray and fill ~70% of the frame.',
          ),
        RejectionReason.notBlue => (
            Icons.format_color_reset_rounded,
            'Not a blue stone',
            "This stone's colour is outside the blue sapphire range. GemEye "
                'grades blue sapphires only.',
          ),
        RejectionReason.notRecognised => (
            Icons.help_outline_rounded,
            'Not recognised as a blue sapphire',
            'This image looks different from the blue sapphires GemEye was '
                'trained on. Check the stone and capture setup, or ask a '
                'gemologist.',
          ),
      };

  void _showWhy(BuildContext context) {
    AppDialog.alert(
      context,
      title: 'Why was this rejected?',
      message: 'Before grading, every photo passes 3 checks:\n\n'
          '1. Stone detection - a gemstone must be found in the centre of '
          'the photo.\n'
          '2. Colour range - its hue must be inside the blue sapphire '
          'range.\n'
          '3. Recognition - it must look like the blue sapphires GemEye was '
          'trained on.\n\n'
          'This photo did not pass one of these checks, so no grade was '
          'given.',
      actionLabel: 'Got it',
      type: AppDialogType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = _content;
    final hue = reason == RejectionReason.notBlue ? measuredHue : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GemAppBar(
        title: 'Result',
        leading: GemAppBarLeading.back,
        onLeadingPressed: () => CaptureScreen.popTo(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxxl,
                    AppSpacing.huge, AppSpacing.xxxl, AppSpacing.xl),
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                          color: AppColors.warningTint,
                          shape: BoxShape.circle),
                      child: Icon(icon, size: 36, color: AppColors.warning),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: AppText.screenTitle.copyWith(height: 1.3)),
                  const SizedBox(height: AppSpacing.md),
                  Text(body,
                      textAlign: TextAlign.center,
                      style: AppText.body14.copyWith(
                          height: 1.5, color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xxxl),
                  CardContainer(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image_outlined,
                                    color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Your photo',
                                  style: AppText.body14Medium),
                              if (sessionId != null &&
                                  sessionId!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(sessionId!,
                                    style: AppText.caption.copyWith(
                                        color: AppColors.textSecondary)),
                              ],
                              if (hue != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: HSVColor.fromAHSV(
                                                1, hue % 360, 0.63, 0.49)
                                            .toColor(),
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.xs),
                                        border: Border.all(
                                            color: AppColors.border),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Text('Measured hue ',
                                        style: AppText.secondary.copyWith(
                                            color: AppColors.textSecondary)),
                                    Text('${hue.round()}°',
                                        style: AppText.monoValue.copyWith(
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: TextLinkButton(
                      label: 'Why was this rejected?',
                      trailingIcon: Icons.chevron_right_rounded,
                      onPressed: () => _showWhy(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Retake',
                    icon: Icons.photo_camera_rounded,
                    onPressed: () => CaptureScreen.popTo(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          "GemEye measures colour; it cannot confirm a gem's identity.",
                          textAlign: TextAlign.center,
                          style: AppText.caption.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
