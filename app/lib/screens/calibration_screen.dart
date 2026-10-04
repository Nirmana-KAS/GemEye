import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../services/calibration_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/calibration_history_sheet.dart';
import '../widgets/card_container.dart';
import '../widgets/gem_app_bar.dart';
import 'calibration_patch_screen.dart';
import 'capture_screen.dart';

/// Reference swatch colours, in [kCalibrationPatches] order.
const List<Color> kPatchColors = [
  AppColors.patchWhite,
  AppColors.patchBlack,
  AppColors.patchGrey18,
  AppColors.patchGrey50,
  AppColors.patchBlue,
  AppColors.patchRed,
];

/// "#RRGGBB" for an RGB triple (0-255).
String rgbHex(List<int> rgb) =>
    '#${rgb.map((v) => v.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';

/// Colour Calibration start: explains the 6-patch flow and starts it.
class CalibrationScreen extends StatelessWidget {
  /// When true, a saved calibration returns to the previous screen
  /// (Capture) instead of opening a new Capture.
  final bool popOnSave;

  const CalibrationScreen({super.key, this.popOnSave = false});

  /// Opens Capture when the calibration is valid, otherwise Calibration.
  static void openGrading(BuildContext context) {
    if (CalibrationService.isValidNow) {
      Navigator.of(context).push(CaptureScreen.route());
      return;
    }
    AppSnackBar.show(context,
        message: 'Calibrate your phone before grading.',
        type: AppSnackBarType.info);
    AppRoutes.push(context, const CalibrationScreen());
  }

  Future<void> _start(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CalibrationPatchScreen()),
    );
    if (saved == true && context.mounted) {
      if (popOnSave) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(CaptureScreen.route());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GemAppBar(
        title: 'Colour Calibration',
        leading: GemAppBarLeading.back,
        actions: [
          IconButton(
            tooltip: 'Calibration history',
            color: AppColors.onPrimary,
            icon: const Icon(Icons.history_rounded),
            onPressed: () => CalibrationHistorySheet.show(context),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  _buildIntro(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildChecklist(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPatches(),
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Takes about 2 minutes. Valid for this session (8 hours).',
                            style: AppText.body14.copyWith(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            CalibrationBottomBar(
              child: PrimaryButton(
                label: 'Start Calibration',
                onPressed: () => _start(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return CardContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.palette_rounded,
                size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your phone changes colours. GemEye measures 6 known colour patches and corrects every photo in this session.',
                  style: AppText.body14.copyWith(height: 1.5),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Use the same Pro-mode exposure for the patches and the stones.',
                  style: AppText.body14Medium.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist() {
    const items = [
      (Icons.wb_incandescent_rounded, 'Same lighting you will grade in'),
      (Icons.videocam_rounded, 'Phone on tripod'),
      (Icons.flare_rounded, 'Macro lens + CPL attached'),
      (Icons.wb_sunny_rounded,
          'Camera in Pro mode, white balance ‘Daylight’ locked'),
    ];
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Before you start', style: AppText.sectionHeader),
          for (final (icon, text) in items) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: Text(text, style: AppText.body14)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatches() {
    Widget tile(int i) {
      final p = kCalibrationPatches[i];
      return Column(
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: kPatchColors[i],
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('${i + 1}',
                      style: AppText.button
                          .copyWith(fontSize: 11, color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(p.name,
              style: AppText.body14Medium.copyWith(fontSize: 12),
              maxLines: 1),
          const SizedBox(height: AppSpacing.xxs),
          Text(rgbHex(p.rgb),
              style: AppText.monoValue
                  .copyWith(fontSize: 11, color: AppColors.textSecondary)),
        ],
      );
    }

    Widget row(int start) => Row(
          children: [
            for (var i = start; i < start + 3; i++)
              Expanded(child: tile(i)),
          ],
        );

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('6 patches, in this order', style: AppText.sectionHeader),
          const SizedBox(height: AppSpacing.xxs),
          const Text('One photo per patch · patch fills the frame',
              style: AppText.secondary),
          const SizedBox(height: AppSpacing.lg),
          row(0),
          const SizedBox(height: AppSpacing.lg),
          row(3),
        ],
      ),
    );
  }
}

/// White bottom action area with a top border, shared by the calibration
/// screens.
class CalibrationBottomBar extends StatelessWidget {
  final Widget child;

  const CalibrationBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: child,
    );
  }
}
