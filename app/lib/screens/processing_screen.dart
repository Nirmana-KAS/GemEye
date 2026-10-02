import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';
import '../models/grade_result.dart';
import '../services/calibration_service.dart';
import '../services/grading_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_dialog.dart';
import '../widgets/step_progress.dart';
import 'capture_screen.dart';
import 'not_accepted_screen.dart';
import 'repeatability_summary_screen.dart';
import 'result_screen.dart';

/// Processing: grades one photo (or the 3 Repeatability photos) and opens
/// Grade Result, Repeatability Summary or Not Accepted.
class ProcessingScreen extends StatefulWidget {
  final List<String> imagePaths;

  const ProcessingScreen({super.key, required this.imagePaths});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  static const List<String> _steps = [
    'Uploading photo',
    'Applying colour correction',
    'Checking image (stone, colour, quality)',
    'Measuring 12 colour values',
    'Running AI ensemble (CNN + Random Forest)',
    'Preparing report',
  ];

  int _currentStep = 0;

  /// Kept across retries so a retry does not use up a new stone ID.
  String? _stoneId;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _currentStep = 0);
    try {
      // TODO(backend): advance the steps from server progress instead of
      // the demo timing below.
      for (var i = 0; i < _steps.length; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        setState(() => _currentStep = i + 1);
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final sessionId = CalibrationService.session.value?.id ?? '';
      final stoneId = _stoneId ??= await StorageService.getNextStoneId();
      final results = <GradeResult>[];
      for (final path in widget.imagePaths) {
        results.add(await GradingService.grade(
            imagePath: path, stoneId: stoneId, sessionId: sessionId));
      }
      if (!mounted) return;
      _open(results.length == 1
          ? ResultScreen(
              imagePath: results.first.capturedImagePath,
              gradeResult: results.first)
          : RepeatabilitySummaryScreen(results: results));
    } on GradingRejectedException catch (e) {
      // TODO(backend): thrown by GradingService when the server returns a
      // rejection status (no_stone, not_blue, not_recognised).
      if (!mounted) return;
      _open(NotAcceptedScreen(
        reason: e.reason,
        imagePath: widget.imagePaths.last,
        sessionId: CalibrationService.session.value?.id,
        measuredHue: e.measuredHue,
      ));
    } on GradingNoConnectionException {
      // TODO(backend): thrown by GradingService on SocketException.
      if (!mounted) return;
      final retry = await AppDialog.confirm(
        context,
        title: 'No connection',
        message:
            'Check your internet connection and try again. Your photo is kept.',
        confirmLabel: 'Retry',
        cancelLabel: 'Cancel',
        type: AppDialogType.danger,
        icon: Icons.wifi_off_rounded,
      );
      if (!mounted) return;
      retry ? _run() : Navigator.of(context).pop();
    } on GradingTimeoutException {
      // TODO(backend): thrown by GradingService on TimeoutException.
      if (!mounted) return;
      await AppDialog.alert(
        context,
        title: 'Server is taking too long',
        message: 'The grading server did not respond in time.',
        actionLabel: 'Retry',
        type: AppDialogType.warning,
        icon: Icons.hourglass_top_rounded,
        barrierDismissible: false,
      );
      if (mounted) _run();
    } catch (e) {
      // TODO(backend): GradingException and any unexpected error land here.
      debugPrint('Grading failed: $e');
      if (!mounted) return;
      await AppDialog.alert(
        context,
        title: 'Something went wrong',
        message: 'Please try again later.',
        type: AppDialogType.danger,
        barrierDismissible: false,
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  /// Opens [screen] above Capture, dropping Photo Check and Processing.
  void _open(Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (r) => r.settings.name == CaptureScreen.routeName || r.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.darkIcons,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.huge, 72,
                        AppSpacing.huge, AppSpacing.xxxl),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Lottie.asset(
                              'assets/animations/sapphire_rotate.json',
                              repeat: true,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset('assets/images/logo.png'),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const Text('Grading your stone',
                            style: AppText.screenTitle),
                        const SizedBox(height: 40),
                        VerticalStepProgress(
                            labels: _steps, current: _currentStep),
                        const Spacer(),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'Usually 2-5 seconds',
                          style: AppText.body14.copyWith(
                              fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
