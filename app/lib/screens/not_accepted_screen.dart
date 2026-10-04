import 'dart:io';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/grading_response.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_dialog.dart';
import '../widgets/card_container.dart';
import '../widgets/gem_app_bar.dart';
import 'capture_screen.dart';

/// Result when the server refuses the photo (a gate failed). No grade is
/// shown. The body text is the server's message; the photo card shows the
/// gate measurement behind the decision.
class NotAcceptedScreen extends StatelessWidget {
  final GradingResponse response;
  final String imagePath;
  final String? sessionId;

  const NotAcceptedScreen({
    super.key,
    required this.response,
    required this.imagePath,
    this.sessionId,
  });

  GradingStatus get _status => response.status;

  (IconData, String, String) get _content => switch (_status) {
        GradingStatus.noStone => (
            Icons.image_search_rounded,
            'No gemstone detected',
            "We couldn't find a stone in this photo. Centre the stone on the "
                'white tray and fill ~70% of the frame.',
          ),
        GradingStatus.blurry => (
            Icons.blur_on_rounded,
            'Photo is blurry',
            'The photo is blurry. Refocus on the stone and retake it.',
          ),
        GradingStatus.notBlue => (
            Icons.format_color_reset_rounded,
            'Not a blue stone',
            "This stone's colour is outside the blue sapphire range. GemEye "
                'grades blue sapphires only.',
          ),
        GradingStatus.notRecognised => (
            Icons.help_outline_rounded,
            'Not recognised as a blue sapphire',
            'This image looks different from the blue sapphires GemEye was '
                'trained on. Check the stone and capture setup, or ask a '
                'gemologist.',
          ),
        GradingStatus.invalidImage => (
            Icons.broken_image_outlined,
            'Photo cannot be used',
            'The image could not be read or is too small. Retake it at full '
                'resolution.',
          ),
        GradingStatus.ok || GradingStatus.unknown => (
            Icons.help_outline_rounded,
            'Photo not accepted',
            'This photo could not be graded. Please retake it.',
          ),
      };

  double? _diag(String key) => (response.diagnostics[key] as num?)?.toDouble();

  /// The gate measurement shown under "Your photo": (label, value, minimum).
  (String, String, String?)? get _measurement {
    switch (_status) {
      case GradingStatus.blurry:
        final v = _diag('blur_variance');
        if (v == null) return null;
        final min = _diag('blur_min_variance');
        return ('Sharpness ', v.toStringAsFixed(1), min?.toStringAsFixed(1));
      case GradingStatus.invalidImage:
        final v = _diag('short_side_px');
        if (v == null) return null;
        final min = _diag('min_short_side_px');
        return (
          'Short side ',
          '${v.round()} px',
          min == null ? null : '${min.round()} px'
        );
      case GradingStatus.noStone:
        final v = _diag('gate_stone_area');
        if (v == null) return null;
        final min = _diag('no_stone_min_area');
        return (
          'Stone area ',
          '${(v * 100).toStringAsFixed(1)}%',
          min == null ? null : '${(min * 100).toStringAsFixed(1)}%'
        );
      default:
        return null;
    }
  }

  void _showWhy(BuildContext context) {
    AppDialog.alert(
      context,
      title: 'Why was this rejected?',
      message: 'Before grading, every photo passes 5 checks:\n\n'
          '1. Image - the photo must be readable and large enough.\n'
          '2. Stone detection - a gemstone must be found in the centre of '
          'the photo.\n'
          '3. Sharpness - the stone must be in focus.\n'
          '4. Colour range - its hue must be inside the blue sapphire '
          'range.\n'
          '5. Recognition - it must look like the blue sapphires GemEye was '
          'trained on.\n\n'
          'This photo did not pass one of these checks, so no grade was '
          'given.',
      actionLabel: 'Got it',
      type: AppDialogType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (icon, title, fallback) = _content;
    final message = response.message?.trim();
    final body = message == null || message.isEmpty ? fallback : message;
    final hue =
        _status == GradingStatus.notBlue ? response.measuredHue : null;
    final measurement = _measurement;

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
                              if (measurement != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(measurement.$1,
                                        style: AppText.secondary.copyWith(
                                            color: AppColors.textSecondary)),
                                    Text(measurement.$2,
                                        style: AppText.monoValue.copyWith(
                                            fontWeight: FontWeight.w500)),
                                    if (measurement.$3 != null) ...[
                                      Text(' (minimum ',
                                          style: AppText.secondary.copyWith(
                                              color: AppColors.textSecondary)),
                                      Text(measurement.$3!,
                                          style: AppText.monoValue),
                                      Text(')',
                                          style: AppText.secondary.copyWith(
                                              color: AppColors.textSecondary)),
                                    ],
                                  ],
                                ),
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
