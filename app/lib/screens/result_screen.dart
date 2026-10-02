import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/grade_result.dart';
import '../services/grade_record_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/gem_app_bar.dart';
import '../widgets/grade_badge_card.dart';
import '../widgets/probability_bar.dart';
import '../widgets/status_banner.dart';
import 'capture_screen.dart';
import 'certificate_screen.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final GradeResult? gradeResult;

  const ResultScreen({
    super.key,
    required this.imagePath,
    this.gradeResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  late GradeResult _result;
  bool _isSaving = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _result = widget.gradeResult ?? _createMockResult();
  }

  GradeResult _createMockResult() {
    return GradeResult(
      stoneId: GradeRecordService.placeholderStoneId,
      gradeNumber: 3,
      gradeName: 'Vivid',
      tradeName: 'Royal Blue',
      confidence: 92.4,
      uncertaintyRange: 0.2,
      labL: 42.3,
      labA: 8.9,
      labB: -27.0,
      labC: 28.4,
      hue: 228,
      saturation: 88,
      brightness: 62,
      deltaE: 1.2,
      capturedImagePath: widget.imagePath,
    );
  }

  bool get _borderline => _result.confidence < ConfidenceBadge.referThreshold;

  /// Per-grade probabilities (percent, G1-G7).
  // TODO(backend): return the ensemble probabilities once GradeResult
  // carries them; the "How sure is the model" card and the second grade in
  // the borderline banner stay hidden until then.
  List<double>? get _probabilities => null;

  /// Second most likely grade, when probabilities are available.
  int? get _secondGrade {
    final p = _probabilities;
    if (p == null || p.length < 7) return null;
    var best = -1;
    for (var i = 0; i < p.length; i++) {
      if (i + 1 == _result.gradeNumber) continue;
      if (best < 0 || p[i] > p[best]) best = i;
    }
    return best + 1;
  }

  Future<void> _saveAndGradeNext() async {
    setState(() => _isSaving = true);
    try {
      _result = await GradeRecordService.save(_result);
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Stone saved - ${_result.stoneId}',
            type: AppSnackBarType.success);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('Save failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Failed to save result', type: AppSnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _exportCertificate() async {
    setState(() => _isExporting = true);
    try {
      _result = await GradeRecordService.prepareCertificate(_result);

      Uint8List stoneImageBytes;
      try {
        stoneImageBytes = await File(widget.imagePath).readAsBytes();
      } catch (_) {
        stoneImageBytes = Uint8List(0);
      }

      if (mounted) {
        AppRoutes.push(
          context,
          CertificateScreen(
            result: _result,
            stoneImageBytes: stoneImageBytes,
          ),
        );
      }
    } catch (e) {
      debugPrint('Certificate failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Failed to generate certificate',
            type: AppSnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareResult() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/gemeye_result.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'GemEye Grade ${_result.gradeNumber} - ${_result.gradeName} (${_result.tradeName})',
      );
    } catch (e) {
      debugPrint('Share failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Failed to share result', type: AppSnackBarType.error);
      }
    }
  }

  /// Retake: back to Capture when this result came from a grading run.
  void _retake() => CaptureScreen.popTo(context);

  @override
  Widget build(BuildContext context) {
    final probabilities = _probabilities;
    final second = _secondGrade;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GemAppBar(
        title: 'Colour Grading Report',
        leading: GemAppBarLeading.back,
        onLeadingPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            color: AppColors.onPrimary,
            tooltip: 'Share',
            onPressed: _shareResult,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_borderline) ...[
                StatusBanner(
                  type: StatusBannerType.warning,
                  message: second == null
                      ? 'Borderline - gemologist review recommended'
                      : 'Borderline between Grade ${_result.gradeNumber} and '
                          'Grade $second - gemologist review recommended',
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: AppColors.background,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStoneImage(),
                      const SizedBox(height: AppSpacing.lg),
                      GradeBadgeCard(
                        gradeNumber: _result.gradeNumber,
                        gradeName: _result.gradeName,
                        tradeName: _result.tradeName,
                        chips: [
                          UncertaintyPill.range(_result.uncertaintyRange),
                          ConfidenceBadge(
                              confidence: _result.confidence, onDark: true),
                        ],
                      ),
                      if (probabilities != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        ProbabilityBarCard(
                          probabilities: probabilities,
                          predictedGrade: _result.gradeNumber,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      _buildColourValues(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildGradCam(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_borderline) ...[
                PrimaryButton(
                  label: 'Save as Referred',
                  icon: Icons.outgoing_mail,
                  isLoading: _isSaving,
                  onPressed: _isExporting ? null : _saveAndGradeNext,
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: 'Retake',
                  icon: Icons.photo_camera_rounded,
                  onPressed: _isSaving ? null : _retake,
                ),
              ] else ...[
                PrimaryButton(
                  label: 'Save & Grade Next',
                  icon: Icons.bookmark_add_rounded,
                  isLoading: _isSaving,
                  onPressed: _isExporting ? null : _saveAndGradeNext,
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: _isExporting ? 'Preparing...' : 'Export Certificate',
                  icon: Icons.workspace_premium_rounded,
                  onPressed:
                      _isExporting || _isSaving ? null : _exportCertificate,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                [
                  'Stone ${_result.stoneId}',
                  if (_result.sessionId.isNotEmpty)
                    'Session ${_result.sessionId}',
                  DateFormat('d MMM yyyy, HH:mm').format(_result.capturedAt),
                  // TODO(backend): add the model version from the response.
                ].join(' · '),
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(height: 1.6),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoneImage() {
    final rgb = _result.measuredRgb;
    return Container(
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(widget.imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: AppColors.surface,
              child: Icon(Icons.diamond_rounded,
                  size: 48, color: AppColors.textMuted),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            top: AppSpacing.md,
            child: Container(
              height: 24,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs, 0, AppSpacing.md, 0),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, rgb[0], rgb[1], rgb[2]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(_result.measuredHex,
                      style: AppText.monoValue
                          .copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TODO(backend): add CIECAM02 tiles (J, M, h, s, C) in the same style.
  Widget _buildColourValues() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GemEyeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COLOUR VALUES',
            style: TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GemEyeColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildValueRow('Lightness', _result.labL.toStringAsFixed(1), 'Green-Red', _result.labA.toStringAsFixed(1)),
          const SizedBox(height: 8),
          _buildValueRow('Blue-Yellow', _result.labB.toStringAsFixed(1), 'Chroma', _result.labC.toStringAsFixed(1)),
          const SizedBox(height: 8),
          _buildValueRow('Hue', '${_result.hue.toStringAsFixed(0)}°', 'Saturation', '${_result.saturation.toStringAsFixed(0)}%'),
          const SizedBox(height: 8),
          _buildValueRow('Brightness', '${_result.brightness.toStringAsFixed(0)}%', 'Delta E', _result.deltaE.toStringAsFixed(1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: GemEyeColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hex Value',
                  style: TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 12,
                    color: GemEyeColors.textSecondary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(int.parse(_result.gradeColourHex.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(color: GemEyeColors.border),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _result.gradeColourHex,
                      style: const TextStyle(
                        fontFamily: GemEyeFonts.mono,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GemEyeColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradCam() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GemEyeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GRAD-CAM HEATMAP',
            style: TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GemEyeColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const RadialGradient(
                center: Alignment(-0.1, 0.0),
                colors: [
                  Color(0x99EF4444),
                  Color(0x66F59E0B),
                  Color(0x3310B981),
                  Color(0x331B3A8C),
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Heatmap generated after model deployment',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Connect to cloud backend to enable',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 9,
                      color: Colors.white54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Red = high influence on prediction · Blue = low influence',
            style: TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 10,
              color: GemEyeColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: GemEyeColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label1,
                  style: const TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 12,
                    color: GemEyeColors.textSecondary,
                  ),
                ),
                Text(
                  value1,
                  style: const TextStyle(
                    fontFamily: GemEyeFonts.mono,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GemEyeColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: GemEyeColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label2,
                  style: const TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 12,
                    color: GemEyeColors.textSecondary,
                  ),
                ),
                Text(
                  value2,
                  style: const TextStyle(
                    fontFamily: GemEyeFonts.mono,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GemEyeColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
