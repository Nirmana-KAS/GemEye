import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../services/calibration_service.dart';
import '../services/photo_check_service.dart';
import '../services/stone_capture_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/card_container.dart';
import '../widgets/gem_app_bar.dart';
import 'capture_screen.dart';
import 'processing_screen.dart';
import 'repeatability_capture_screen.dart';

/// Number of captures in Repeatability mode.
const int kRepeatabilityCaptures = 3;

/// Photo Check: shown after the cropper. Grading is blocked while the
/// sharpness, framing or calibration check fails.
class PhotoCheckScreen extends StatefulWidget {
  final String imagePath;

  /// Accepted photos of the same stone from earlier repeatability captures.
  final List<String> previousPaths;
  final bool repeatability;

  const PhotoCheckScreen({
    super.key,
    required this.imagePath,
    this.previousPaths = const [],
    this.repeatability = false,
  });

  /// Picks from [source], crops, then opens Photo Check. Shows a friendly
  /// snackbar when the camera or gallery cannot be opened.
  static Future<void> captureFrom(
    BuildContext context,
    ImageSource source, {
    List<String> previousPaths = const [],
    bool repeatability = false,
  }) async {
    try {
      final shot = await StoneCaptureService.pickAndCrop(source);
      if (shot == null || !context.mounted) return;
      if (shot.cropFailed) {
        AppSnackBar.show(context,
            message: 'Crop unavailable - using original image',
            type: AppSnackBarType.warning);
      }
      AppRoutes.push(
        context,
        PhotoCheckScreen(
          imagePath: shot.path,
          previousPaths: previousPaths,
          repeatability: repeatability,
        ),
      );
    } catch (e) {
      debugPrint('Capture failed: $e');
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: source == ImageSource.camera
            ? 'Could not open the camera. Please try again.'
            : 'Could not open the gallery. Please try again.',
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  State<PhotoCheckScreen> createState() => _PhotoCheckScreenState();
}

class _PhotoCheckScreenState extends State<PhotoCheckScreen> {
  PhotoCheckResult? _result;
  bool _analysisFailed = false;

  @override
  void initState() {
    super.initState();
    _analyse();
  }

  Future<void> _analyse() async {
    try {
      final r = await PhotoCheckService.analyse(File(widget.imagePath));
      if (!mounted) return;
      setState(() => _result = r);
      if (!r.isSharp) {
        AppSnackBar.show(
          context,
          message: 'Image is blurry - please recapture',
          type: AppSnackBarType.error,
          actionLabel: 'Retake',
          onAction: _retake,
        );
      }
    } catch (e) {
      debugPrint('Photo check failed: $e');
      if (!mounted) return;
      setState(() => _analysisFailed = true);
      AppSnackBar.show(context,
          message: 'Could not read this photo. Please recapture.',
          type: AppSnackBarType.error);
    }
  }

  void _retake() {
    if (mounted) Navigator.of(context).maybePop();
  }

  int get _captureNumber => widget.previousPaths.length + 1;

  bool get _isLastCapture =>
      !widget.repeatability || _captureNumber >= kRepeatabilityCaptures;

  void _accept() {
    final paths = [...widget.previousPaths, widget.imagePath];
    if (_isLastCapture) {
      AppRoutes.push(context, ProcessingScreen(imagePaths: paths));
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (_) => RepeatabilityCaptureScreen(acceptedPaths: paths)),
      (r) => r.settings.name == CaptureScreen.routeName || r.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = CalibrationService.session.value;
    final calibrated = session?.isValid ?? false;
    final r = _result;
    final checking = r == null && !_analysisFailed;
    final canGrade = r != null && r.isSharp && r.stoneInFrame && calibrated;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GemAppBar(
        title: widget.repeatability
            ? 'Photo Check · $_captureNumber of $kRepeatabilityCaptures'
            : 'Photo Check',
        leading: GemAppBarLeading.back,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  _buildPreview(),
                  const SizedBox(height: AppSpacing.lg),
                  CardContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
                    child: Column(
                      children: [
                        _CheckRow(
                          state: checking
                              ? _CheckState.pending
                              : (r?.isSharp ?? false)
                                  ? _CheckState.pass
                                  : _CheckState.fail,
                          title: checking
                              ? 'Sharpness - checking'
                              : (r?.isSharp ?? false)
                                  ? 'Sharpness - Sharp'
                                  : 'Sharpness - Blurry',
                          failText: 'Refocus and recapture',
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _CheckRow(
                          state: checking
                              ? _CheckState.pending
                              : (r?.stoneInFrame ?? false)
                                  ? _CheckState.pass
                                  : _CheckState.fail,
                          title: 'Stone in frame',
                          failText: 'Stone not found - recentre',
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _CheckRow(
                          state: calibrated
                              ? _CheckState.pass
                              : _CheckState.fail,
                          title: session == null
                              ? 'No calibration session'
                              : calibrated
                                  ? 'Calibration session ${session.id}'
                                  : 'Calibration session ${session.id} expired',
                          failText: 'Recalibrate before grading',
                        ),
                      ],
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
                    label: _isLastCapture ? 'Grade This Stone' : 'Use This Photo',
                    onPressed: canGrade ? _accept : null,
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: 'Retake',
                    icon: Icons.refresh_rounded,
                    onPressed: _retake,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.file(
          File(widget.imagePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_outlined,
                size: 48, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

enum _CheckState { pending, pass, fail }

class _CheckRow extends StatelessWidget {
  final _CheckState state;
  final String title;
  final String failText;

  const _CheckRow({
    required this.state,
    required this.title,
    required this.failText,
  });

  @override
  Widget build(BuildContext context) {
    final Widget icon = switch (state) {
      _CheckState.pending => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
              backgroundColor: AppColors.border),
        ),
      _CheckState.pass => const Icon(Icons.check_circle_rounded,
          size: 18, color: AppColors.success),
      _CheckState.fail =>
        const Icon(Icons.cancel_rounded, size: 18, color: AppColors.error),
    };
    final tint = switch (state) {
      _CheckState.pending => AppColors.surface,
      _CheckState.pass => AppColors.successTint,
      _CheckState.fail => AppColors.errorTint,
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: icon,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.body14Medium.copyWith(height: 1.35)),
                  if (state == _CheckState.fail) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(failText,
                        style: AppText.secondary.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: AppColors.error)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
