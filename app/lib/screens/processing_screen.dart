import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';
import '../config/theme.dart';
import '../models/grade_result.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../services/account_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/calibration_service.dart';
import '../services/grading_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_dialog.dart';
import '../widgets/step_progress.dart';
import 'capture_screen.dart';
import 'not_accepted_screen.dart';
import 'repeatability_summary_screen.dart';
import 'result_screen.dart';

/// Processing: grades one photo (or the 3 Repeatability photos) on the
/// server and opens Grade Result, Repeatability Summary or Not Accepted.
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

  /// While the server works, the server-side steps advance on this period,
  /// stopping before "Preparing report" until the response arrives.
  static const Duration _serverStepPeriod = Duration(milliseconds: 600);

  int _currentStep = 0;
  int _photo = 0;
  Timer? _serverTicker;

  /// One request id per photo, kept across retries so a retried upload
  /// returns the original grading instead of a new one.
  late final List<String> _requestIds = [
    for (final _ in widget.imagePaths) const Uuid().v4(),
  ];

  /// Photos already graded (kept across retries).
  final List<GradeResult> _results = [];

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _serverTicker?.cancel();
    super.dispose();
  }

  void _setStep(int step) {
    if (mounted && step != _currentStep) setState(() => _currentStep = step);
  }

  /// Upload finished: the server is working on the photo.
  void _serverStarted() {
    if (_serverTicker != null) return;
    _setStep(1);
    _serverTicker = Timer.periodic(_serverStepPeriod, (_) {
      if (_currentStep < _steps.length - 2) _setStep(_currentStep + 1);
    });
  }

  void _stopTicker() {
    _serverTicker?.cancel();
    _serverTicker = null;
  }

  Future<void> _run() async {
    final session = CalibrationService.session.value;
    try {
      for (var i = _results.length; i < widget.imagePaths.length; i++) {
        _stopTicker();
        if (mounted) {
          setState(() {
            _photo = i;
            _currentStep = 0;
          });
        }
        final path = widget.imagePaths[i];
        final response = await GradingService.gradeStone(
          File(path),
          patches: session?.measured,
          sessionId: session?.id,
          referralThreshold: SettingsService.referralThreshold.value / 100,
          requestId: _requestIds[i],
          onUploadProgress: (sent, total) {
            if (total > 0 && sent >= total) _serverStarted();
          },
        );
        _stopTicker();
        _setStep(_steps.length);
        if (!mounted) return;
        if (!response.isOk) {
          _open(NotAcceptedScreen(
            response: response,
            imagePath: path,
            sessionId: session?.id,
          ));
          return;
        }
        _results.add(response.result!);
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _open(_results.length == 1
          ? ResultScreen(
              imagePath: _results.first.capturedImagePath,
              gradeResult: _results.first)
          : RepeatabilitySummaryScreen(results: List.of(_results)));
    } on ApiException catch (e) {
      _stopTicker();
      if (mounted) await _handleError(e);
    } catch (e) {
      _stopTicker();
      debugPrint('Grading failed: $e');
      if (mounted) await _somethingWentWrong();
    }
  }

  Future<void> _handleError(ApiException e) async {
    switch (e.code) {
      case ApiErrorCode.offline:
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
        if (retry) {
          _run();
        } else {
          await _notifyFailed('No internet connection.');
          if (mounted) Navigator.of(context).pop();
        }
      case ApiErrorCode.timeout:
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
      case ApiErrorCode.maintenance:
        await AppDialog.alert(
          context,
          title: 'Under maintenance',
          message: e.message,
          type: AppDialogType.warning,
          icon: Icons.build_rounded,
          barrierDismissible: false,
        );
        await _notifyFailed(e.message);
        if (mounted) Navigator.of(context).pop();
      case ApiErrorCode.accountDeleted:
        await AppDialog.alert(
          context,
          title: 'Account deleted',
          message: 'This account has been deleted. You will be signed out.',
          actionLabel: 'OK',
          type: AppDialogType.danger,
          icon: Icons.person_off_rounded,
          barrierDismissible: false,
        );
        await AuthService.endSession(
            beforeSignOut: AccountService.clearLocalData);
      case ApiErrorCode.unauthorized:
      case ApiErrorCode.reauthRequired:
        await AuthService.showSessionExpired();
      case ApiErrorCode.tooLarge:
        await AppDialog.alert(
          context,
          title: 'Photo too large',
          message: e.message,
          type: AppDialogType.warning,
          icon: Icons.photo_size_select_large_rounded,
          barrierDismissible: false,
        );
        await _notifyFailed(e.message);
        if (mounted) Navigator.of(context).pop();
      case ApiErrorCode.serverError:
      case ApiErrorCode.badRequest:
      case ApiErrorCode.notFound:
      case ApiErrorCode.conflict:
        await _somethingWentWrong();
    }
  }

  /// "Grading failed" notification; tapping it opens Capture to try again.
  Future<void> _notifyFailed(String reason) => NotificationService.add(
        type: AppNotificationType.error,
        title: 'Grading failed',
        message: '$reason Tap to try again.',
        action: AppNotificationAction.openCapture,
      );

  Future<void> _somethingWentWrong() async {
    await _notifyFailed('Something went wrong on our side.');
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
                        if (widget.imagePaths.length > 1) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Photo ${_photo + 1} of ${widget.imagePaths.length}',
                            style: AppText.secondary
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
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
