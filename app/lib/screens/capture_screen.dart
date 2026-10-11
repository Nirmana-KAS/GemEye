import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class _CaptureScreenState extends State<CaptureScreen>
    with SingleTickerProviderStateMixin {
  static const String _tickKey = 'capture_setup_ticked_session';

  late final AnimationController _pulse;
  late final Animation<double> _pulseOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.35), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.35, end: 1.0), weight: 1),
  ]).animate(_pulse);
  String? _tickedSessionId;
  bool _repeatability = false;
  bool _pulseStarted = false;
  ImageSource? _busySource;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _loadTick();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pulseStarted) return;
    _pulseStarted = true;
    if (!MediaQuery.disableAnimationsOf(context)) _runPulse();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Opacity 1.0 -> 0.35 -> 1.0, three times, then fully visible.
  Future<void> _runPulse() async {
    for (var i = 0; i < 3; i++) {
      if (!mounted) return;
      try {
        await _pulse.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }
  }

  Future<void> _loadTick() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_tickKey);
      if (mounted) setState(() => _tickedSessionId = id);
    } catch (e) {
      if (kDebugMode) debugPrint('Setup tick not loaded: $e');
    }
  }

  Future<void> _setTick(CalibrationSession session, bool value) async {
    setState(() => _tickedSessionId = value ? session.id : null);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value) {
        await prefs.setString(_tickKey, session.id);
      } else {
        await prefs.remove(_tickKey);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Setup tick not saved: $e');
    }
  }

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
          final allTicked = isSetupTickValid(_tickedSessionId, session);
          final unlocked =
              online && calibrated && allTicked && _busySource == null;

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
                  if (calibrated) ...[
                    FadeTransition(
                      opacity: _pulseOpacity,
                      child: StatusBanner(
                        type: StatusBannerType.error,
                        icon: Icons.warning_amber_rounded,
                        title:
                            'Changed location or lighting? Recalibrate with the CCC card before grading.',
                        message:
                            'Accurate grades need a calibration made in your current light.',
                        actionLabel: 'Recalibrate',
                        onAction: _openCalibration,
                      ),
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
                            'Confirm your setup below to capture',
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
                  _buildChecklist(session, allTicked),
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

  Widget _buildChecklist(CalibrationSession? session, bool allTicked) {
    return CardContainer(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: AppCheckbox(
        value: allTicked,
        onChanged: session != null && session.isValid
            ? (v) => _setTick(session, v)
            : null,
        label: const Text(
            'My setup matches calibration: macro + CPL, white tray, same light'),
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
