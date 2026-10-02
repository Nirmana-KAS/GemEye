import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../services/calibration_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/card_container.dart';
import '../widgets/gem_app_bar.dart';
import '../widgets/step_progress.dart';
import 'calibration_result_screen.dart';
import 'calibration_screen.dart';

const String _notUniformMessage =
    'Patch not uniform - shadow or edge detected. Retake.';

/// Captures the 6 calibration patches one by one. Pops with true once the
/// session is saved from the result screen.
class CalibrationPatchScreen extends StatefulWidget {
  const CalibrationPatchScreen({super.key});

  @override
  State<CalibrationPatchScreen> createState() => _CalibrationPatchScreenState();
}

class _CalibrationPatchScreenState extends State<CalibrationPatchScreen> {
  static const int _patchCount = 6;

  final ImagePicker _picker = ImagePicker();
  final List<PatchMeasurement?> _results =
      List<PatchMeasurement?>.filled(_patchCount, null);

  int _step = 0;
  File? _photo;
  PatchMeasurement? _measurement;
  bool _measuring = false;
  bool _finishing = false;

  CalibrationPatch get _patch => kCalibrationPatches[_step];
  bool get _hasProgress => _step > 0 || _photo != null;
  bool get _isLast => _step == _patchCount - 1;
  bool get _isDarkPatch => _step != 0 && _step != 3;

  Future<void> _capture(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100,
      );
      if (picked == null || !mounted) return;
      final file = File(picked.path);
      setState(() {
        _photo = file;
        _measurement = null;
        _measuring = true;
      });
      final m = await CalibrationService.measurePatch(file);
      if (!mounted) return;
      setState(() {
        _measurement = m;
        _measuring = false;
      });
      if (!m.isUniform) {
        AppSnackBar.show(context,
            message: _notUniformMessage,
            type: AppSnackBarType.error,
            actionLabel: 'Retake',
            onAction: _retake);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Patch capture failed: $e');
      if (!mounted) return;
      setState(() {
        _photo = null;
        _measurement = null;
        _measuring = false;
      });
      AppSnackBar.show(context,
          message: 'Could not read this photo. Try again.',
          type: AppSnackBarType.error);
    }
  }

  void _retake() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _photo = null;
      _measurement = null;
    });
  }

  Future<void> _next() async {
    final m = _measurement;
    if (m == null || !m.isUniform) return;
    _results[_step] = m;
    if (!_isLast) {
      setState(() {
        _step++;
        _photo = null;
        _measurement = null;
      });
      return;
    }

    setState(() => _finishing = true);
    try {
      final session = await CalibrationService.buildSession(
          _results.cast<PatchMeasurement>());
      if (!mounted) return;
      setState(() => _finishing = false);
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
            builder: (_) => CalibrationResultScreen(session: session)),
      );
      if (!mounted || saved == null) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (kDebugMode) debugPrint('Calibration compute failed: $e');
      if (!mounted) return;
      setState(() => _finishing = false);
      AppSnackBar.show(context,
          message: 'Could not compute the calibration. Recalibrate.',
          type: AppSnackBarType.error);
    }
  }

  Future<void> _onBack(bool didPop, Object? result) async {
    if (didPop) return;
    final cancel = await AppDialog.confirm(
      context,
      title: 'Cancel calibration?',
      message: 'Progress will be lost.',
      confirmLabel: 'Cancel calibration',
      cancelLabel: 'Keep going',
      type: AppDialogType.danger,
    );
    if (cancel && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasProgress,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const GemAppBar(
          title: 'Colour Calibration',
          leading: GemAppBarLeading.back,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProgress(),
                      const SizedBox(height: AppSpacing.lg + 2),
                      _buildPatchInfo(),
                      const SizedBox(height: AppSpacing.lg + 2),
                      Expanded(child: _buildStage()),
                    ],
                  ),
                ),
              ),
              CalibrationBottomBar(child: _buildActions()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text('Patch ${_step + 1} of $_patchCount',
                  style: AppText.titleSmall),
            ),
            Text('$_step done', style: AppText.secondary),
          ],
        ),
        const SizedBox(height: AppSpacing.md + 2),
        StepProgress(
          labels: kCalibrationPatches.map((p) => p.name).toList(),
          current: _step,
        ),
      ],
    );
  }

  Widget _buildPatchInfo() {
    return CardContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Swatch(color: kPatchColors[_step], size: 56),
          const SizedBox(width: AppSpacing.lg + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.md,
                  children: [
                    Text(_patch.name, style: AppText.sectionHeader),
                    Text(rgbHex(_patch.rgb),
                        style: AppText.monoValue.copyWith(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Place the ${_patch.name} patch under the lens so it fills the whole frame. No shadows.',
                  style: AppText.body14
                      .copyWith(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage() {
    if (_photo == null) return _buildGuide();
    final m = _measurement;
    final guide = _isDarkPatch ? AppColors.onPrimary : AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_photo!, fit: BoxFit.cover),
                  LayoutBuilder(builder: (context, c) {
                    final side = (c.biggest.shortestSide / 2).clamp(0.0, 140.0);
                    return Center(
                      child: Container(
                        width: side,
                        height: side,
                        decoration: BoxDecoration(
                          border: Border.all(color: guide, width: 2),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                      ),
                    );
                  }),
                  Positioned(
                    left: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Container(
                      height: 22,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        m != null && !m.isUniform
                            ? 'captured photo · not uniform'
                            : 'captured photo',
                        style: AppText.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  if (_measuring)
                    const ColoredBox(
                      color: AppColors.scrim,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.onPrimary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (m != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildMeasurementCard(m),
        ],
      ],
    );
  }

  Widget _buildMeasurementCard(PatchMeasurement m) {
    final rgb = m.meanRgb;
    final ok = m.isUniform;
    return CardContainer(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          _LabelledSwatch(color: kPatchColors[_step], label: 'Reference'),
          const SizedBox(width: AppSpacing.lg + 2),
          _LabelledSwatch(
            color: Color.fromARGB(255, rgb[0], rgb[1], rgb[2]),
            label: 'Measured',
          ),
          const SizedBox(width: AppSpacing.lg + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded,
                        size: 18,
                        color: ok ? AppColors.success : AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(ok ? 'Patch uniform' : 'Patch not uniform',
                          style: AppText.titleSmall),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text('Measured RGB ${rgb.join(', ')}',
                    style: AppText.monoValue
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuide() {
    final guide = _isDarkPatch ? AppColors.onPrimary : AppColors.primary;
    return Column(
      children: [
        Expanded(
          child: FittedBox(
            child: Container(
              width: 168,
              height: 300,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.textPrimary, width: 2),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: kPatchColors[_step],
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: CustomPaint(
                        painter: _GuidePainter(guide),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.textPrimary, width: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md + 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(
              painter: _DashedSquarePainter(AppColors.primary, 1.5, 4),
              child: const SizedBox(width: 12, height: 12),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Flexible(
              child: Text('Patch fills the frame · centre 50% is measured',
                  style: AppText.secondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    if (_photo == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Take Photo',
            icon: Icons.photo_camera_rounded,
            onPressed: () => _capture(ImageSource.camera),
          ),
          const SizedBox(height: AppSpacing.md + 2),
          SecondaryButton(
            label: 'Import from Gallery (Pro mode)',
            icon: Icons.photo_library_rounded,
            onPressed: () => _capture(ImageSource.gallery),
          ),
        ],
      );
    }
    final canNext = _measurement?.isUniform ?? false;
    return Row(
      children: [
        Expanded(
          child: SecondaryButton(
            label: 'Retake',
            icon: Icons.refresh_rounded,
            onPressed: _measuring || _finishing ? null : _retake,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: PrimaryButton(
            label: _isLast ? 'Finish' : 'Next patch',
            isLoading: _finishing,
            onPressed: canNext && !_measuring ? _next : null,
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final double size;

  const _Swatch({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size > 48 ? AppRadius.lg : AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}

class _LabelledSwatch extends StatelessWidget {
  final Color color;
  final String label;

  const _LabelledSwatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Swatch(color: color, size: 40),
        const SizedBox(height: AppSpacing.xs),
        Text(label,
            style: AppText.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
      ],
    );
  }
}

/// Dashed centre square (the measured 50%) and corner brackets.
class _GuidePainter extends CustomPainter {
  final Color color;

  _GuidePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width / 2;
    final square = Rect.fromCenter(
        center: size.center(Offset.zero), width: side, height: side);
    _DashedSquarePainter(color, 2, 6).paintRect(canvas, square);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const inset = 8.0, arm = 14.0;
    final corners = [
      (const Offset(inset, inset), 1.0, 1.0),
      (Offset(size.width - inset, inset), -1.0, 1.0),
      (Offset(inset, size.height - inset), 1.0, -1.0),
      (Offset(size.width - inset, size.height - inset), -1.0, -1.0),
    ];
    for (final (o, dx, dy) in corners) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx + dx * arm, o.dy)
          ..lineTo(o.dx, o.dy)
          ..lineTo(o.dx, o.dy + dy * arm),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) => old.color != color;
}

class _DashedSquarePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dash;

  _DashedSquarePainter(this.color, this.strokeWidth, this.dash);

  void paintRect(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)));
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash * 1.8;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) => paintRect(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(covariant _DashedSquarePainter old) =>
      old.color != color;
}
