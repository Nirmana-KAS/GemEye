import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/calibration_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/calibration_history_sheet.dart';
import '../widgets/card_container.dart';
import '../widgets/gem_app_bar.dart';
import 'calibration_screen.dart';

/// Calibration verdict for an unsaved session. Pops with true when saved,
/// false for Recalibrate, null for back.
class CalibrationResultScreen extends StatefulWidget {
  final CalibrationSession session;

  const CalibrationResultScreen({super.key, required this.session});

  @override
  State<CalibrationResultScreen> createState() =>
      _CalibrationResultScreenState();
}

class _CalibrationResultScreenState extends State<CalibrationResultScreen> {
  bool _saving = false;

  CalibrationSession get _s => widget.session;

  /// Relative residual (fit to the training session); the absolute one for
  /// sessions saved before the relative check.
  double get _match => _s.relativeResidual ?? _s.residual;

  /// Brightness order of the patches, checked once at finish.
  late final String? _orderFailure = patchOrderFailure(_s.measured);

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await CalibrationService.save(_s);
      final sent = await CalibrationService.syncToServer(_s);
      if (!mounted) return;
      AppSnackBar.show(context,
          message: sent
              ? 'Calibrated - match ${_match.toStringAsFixed(2)}'
              : 'Calibrated on this device. It will be sent to the server '
                  'when you are online.',
          type: AppSnackBarType.success,
          actionLabel: 'OK',
          onAction: () {});
      Navigator.of(context).pop(true);
    } catch (e) {
      if (kDebugMode) debugPrint('Calibration save failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.show(context,
          message: 'Could not save the calibration. Try again.',
          type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked =
        _s.quality == CalibrationQuality.poor || _orderFailure != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GemAppBar(
        title: 'Calibration Result',
        leading: GemAppBarLeading.back,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  _buildResidual(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPatches(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDetails(),
                ],
              ),
            ),
            CalibrationBottomBar(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: 'Save & Start Grading',
                    isLoading: _saving,
                    onPressed: blocked ? null : _save,
                  ),
                  const SizedBox(height: AppSpacing.md + 2),
                  SecondaryButton(
                    label: 'Recalibrate',
                    icon: Icons.refresh_rounded,
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResidual() {
    final (dot, tint) = CalibrationHistorySheet.qualityColors(_s.quality);
    final (IconData? icon, Color noteColor, String? note) = _orderFailure !=
            null
        ? (Icons.error_rounded, AppColors.error, _orderFailure)
        : switch (_s.quality) {
            CalibrationQuality.excellent => (null, dot, null),
            CalibrationQuality.acceptable => (
                Icons.warning_rounded,
                AppColors.warning,
                'Lighting differs from the reference setup. Results may be less accurate. For best results, calibrate in even daylight.'
              ),
            CalibrationQuality.poor => (
                Icons.error_rounded,
                AppColors.error,
                'Lighting is too different from the reference setup. Recalibrate in even daylight.'
              ),
          };
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Match to reference setup',
                    style: AppText.label.copyWith(fontSize: 12)),
              ),
              QualityChip(
                  quality: _s.quality,
                  dot: dot,
                  tint: tint,
                  label: matchLabel(_s.quality)),
            ],
          ),
          const SizedBox(height: AppSpacing.md + 2),
          Text(
            _match.toStringAsFixed(2),
            style: AppText.display.copyWith(
              fontSize: 32,
              height: 1,
              color: AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.md + 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: noteColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(note,
                      style: AppText.body14.copyWith(
                          fontSize: 13, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatches() {
    Widget tile(int i) {
      final c = _s.corrected(i);
      final err = _s.relativePerPatchError?[i] ?? _s.perPatchError[i];
      final errColor = err > kRelativeAcceptable
          ? AppColors.error
          : err > kRelativeExcellent
              ? AppColors.warning
              : AppColors.textSecondary;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 36, height: 36, color: kPatchColors[i]),
                  Container(
                      width: 36,
                      height: 36,
                      color: Color.fromARGB(255, c[0], c[1], c[2])),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(kCalibrationPatches[i].name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text('Δ ${err.toStringAsFixed(2)}',
                style:
                    AppText.monoValue.copyWith(fontSize: 11, color: errColor)),
          ],
        ),
      );
    }

    Widget row(int start) => Row(
          children: [
            for (var i = start; i < start + 3; i++) ...[
              if (i > start) const SizedBox(width: AppSpacing.md),
              Expanded(child: tile(i)),
            ],
          ],
        );

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('Patches', style: AppText.sectionHeader)),
              Text('Reference · Corrected',
                  style: TextStyle(
                      fontFamily: AppText.body,
                      fontSize: 11,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          row(0),
          const SizedBox(height: AppSpacing.md),
          row(3),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    final created = DateFormat('d MMM yyyy, HH:mm').format(_s.createdAt);
    final until = DateFormat('HH:mm').format(_s.validUntil);
    final rows = [
      ('Device', _s.deviceModel),
      ('Session', _s.id),
      ('Calibrated', '$created · valid until $until'),
    ];
    return CardContainer(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.border))
                    : null,
              ),
              child: Row(
                children: [
                  Text(rows[i].$1,
                      style: AppText.secondary.copyWith(fontSize: 13)),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(rows[i].$2,
                        textAlign: TextAlign.right,
                        style: AppText.body14Medium.copyWith(fontSize: 13)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Chip label for the relative calibration verdict.
String matchLabel(CalibrationQuality q) => switch (q) {
      CalibrationQuality.excellent => 'Good match',
      CalibrationQuality.acceptable => 'Lighting differs',
      CalibrationQuality.poor => 'Too different',
    };
