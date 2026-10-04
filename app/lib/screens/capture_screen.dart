import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../services/remote_config_service.dart';
import '../services/calibration_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_checkbox.dart';
import '../widgets/card_container.dart';
import '../widgets/dashed_border.dart';
import '../widgets/gem_app_bar.dart';
import '../widgets/pro_mode_guide_sheet.dart';
import '../widgets/status_banner.dart';
import '../widgets/toggle_row.dart';
import 'calibration_screen.dart';
import 'photo_check_screen.dart';

/// Grade a Stone: capture guidance, pre-capture checklist and the two
/// capture paths (Pro mode import, quick camera capture).
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  static const String routeName = 'capture';

  /// Named route so later screens can return to Capture.
  static Route<void> route() => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (_) => const CaptureScreen(),
      );

  /// Pops back to Capture, or to the first route when Capture is not in
  /// the stack.
  static void popTo(BuildContext context) {
    Navigator.of(context)
        .popUntil((r) => r.settings.name == routeName || r.isFirst);
  }

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  static const List<String> _checkLabels = [
    'Macro lens attached',
    'CPL filter on',
    'Stone face-up on white tray',
    'Even daylight, no direct sun',
  ];

  final List<bool> _checks = List<bool>.filled(_checkLabels.length, false);
  bool _repeatability = false;
  ImageSource? _busySource;

  int get _ticked => _checks.where((c) => c).length;

  Future<void> _capture(ImageSource source) async {
    setState(() => _busySource = source);
    try {
      await PhotoCheckScreen.captureFrom(context, source,
          repeatability:
              _repeatability && RemoteConfigService.repeatabilityEnabled);
    } finally {
      if (mounted) setState(() => _busySource = null);
    }
  }

  void _openCalibration() {
    AppRoutes.push(context, const CalibrationScreen(popOnSave: true));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.online,
      builder: (context, online, _) =>
          ValueListenableBuilder<CalibrationSession?>(
        valueListenable: CalibrationService.session,
        builder: (context, session, _) {
          final calibrated = session?.isValid ?? false;
          final allTicked = _ticked == _checkLabels.length;
          final unlocked =
              online && calibrated && allTicked && _busySource == null;
          final remaining = _checkLabels.length - _ticked;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: GemAppBar(
              title: 'Grade a Stone',
              leading: GemAppBarLeading.back,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: Center(
                    child: _CalibrationChip(
                      calibrated: calibrated,
                      onTap: calibrated ? null : _openCalibration,
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  const OfflineBanner(
                      padding: EdgeInsets.only(bottom: AppSpacing.lg)),
                  if (!calibrated) ...[
                    StatusBanner(
                      type: StatusBannerType.error,
                      message: 'Not calibrated · Calibrate before grading',
                      onTap: _openCalibration,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _buildRecommendedCard(unlocked),
                  const SizedBox(height: AppSpacing.lg),
                  _buildQuickCard(unlocked),
                  if (calibrated && !allTicked) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Tick $remaining more check${remaining == 1 ? '' : 's'} below to capture',
                            style: AppText.secondary.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _buildFramingCard(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildChecklist(allTicked),
                  const SizedBox(height: AppSpacing.lg),
                  if (RemoteConfigService.repeatabilityEnabled)
                    ToggleRow(
                      title: 'Repeatability mode',
                      subtitle: '3 captures of the same stone',
                      value: _repeatability,
                      onChanged: (v) => setState(() => _repeatability = v),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedCard(bool unlocked) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, size: 20, color: AppColors.primary),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('Recommended (most accurate)',
                    style: AppText.sectionHeader),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            "Capture in your camera's Pro mode with white balance 'Daylight' locked, then import.",
            style: AppText.body14
                .copyWith(height: 1.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Transform.translate(
            offset: const Offset(-AppSpacing.md, 0),
            child: TextLinkButton(
              label: 'How to set up Pro mode',
              trailingIcon: Icons.chevron_right_rounded,
              onPressed: () => ProModeGuideSheet.show(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            label: 'Import from Gallery',
            icon: Icons.photo_library_rounded,
            isLoading: _busySource == ImageSource.gallery,
            onPressed: unlocked ? () => _capture(ImageSource.gallery) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCard(bool unlocked) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick capture', style: AppText.sectionHeader),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Take Photo',
            icon: Icons.photo_camera_rounded,
            onPressed: unlocked ? () => _capture(ImageSource.camera) : null,
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.textMuted),
              SizedBox(width: AppSpacing.sm),
              Text('Less colour-consistent', style: AppText.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFramingCard() {
    return CardContainer(
      child: Row(
        children: [
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: CustomPaint(
              painter: const DashedBorderPainter(color: AppColors.primary),
              child: Container(
                width: 78,
                height: 78,
                alignment: Alignment.center,
                child: Container(
                  width: 67,
                  height: 67,
                  decoration: const BoxDecoration(
                      color: AppColors.grade4, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Framing', style: AppText.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Stone should fill about 70% of the frame',
                  style: AppText.body14.copyWith(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist(bool allTicked) {
    return CardContainer(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              children: [
                const Expanded(
                    child:
                        Text('Before you capture', style: AppText.titleSmall)),
                Text(
                  '$_ticked of ${_checkLabels.length}',
                  style: AppText.secondary.copyWith(
                    fontWeight: FontWeight.w500,
                    color:
                        allTicked ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < _checkLabels.length; i++)
            AppCheckbox(
              value: _checks[i],
              onChanged: (v) => setState(() => _checks[i] = v),
              label: Text(_checkLabels[i]),
            ),
        ],
      ),
    );
  }
}

/// White app-bar pill: green "Calibrated" or red "Not calibrated".
class _CalibrationChip extends StatelessWidget {
  final bool calibrated;
  final VoidCallback? onTap;

  const _CalibrationChip({required this.calibrated, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        highlightColor: AppColors.surface,
        splashColor: Colors.transparent,
        child: Container(
          height: 28,
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, 10, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                calibrated ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 16,
                color: calibrated ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                calibrated ? 'Calibrated' : 'Not calibrated',
                style: AppText.button
                    .copyWith(fontSize: 11, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
