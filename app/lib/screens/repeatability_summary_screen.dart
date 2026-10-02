import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../models/grade_result.dart';
import '../services/grade_record_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/card_container.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/gem_app_bar.dart';
import '../widgets/grade_badge_card.dart';
import '../widgets/status_banner.dart';
import 'capture_screen.dart';
import 'certificate_screen.dart';

/// Repeatability Summary: the grades of the 3 captures, their agreement and
/// the final grade.
class RepeatabilitySummaryScreen extends StatefulWidget {
  final List<GradeResult> results;

  const RepeatabilitySummaryScreen({super.key, required this.results});

  @override
  State<RepeatabilitySummaryScreen> createState() =>
      _RepeatabilitySummaryScreenState();
}

class _RepeatabilitySummaryScreenState
    extends State<RepeatabilitySummaryScreen> {
  late final int _finalGrade;
  late final int _agree;
  late GradeResult _final;
  bool _isSaving = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // TODO(backend): take the final grade and its confidence from the
    // server. Until then: majority grade, and the most confident capture
    // with that grade is the record that is saved.
    final counts = <int, int>{};
    for (final r in widget.results) {
      counts[r.gradeNumber] = (counts[r.gradeNumber] ?? 0) + 1;
    }
    final best = widget.results.reduce((a, b) {
      final ca = counts[a.gradeNumber]!, cb = counts[b.gradeNumber]!;
      if (ca != cb) return ca > cb ? a : b;
      return a.confidence >= b.confidence ? a : b;
    });
    _finalGrade = best.gradeNumber;
    _agree = counts[_finalGrade]!;
    _final = best;
  }

  bool get _consistent => _agree == widget.results.length;

  bool get _referred =>
      !_consistent || _final.confidence < ConfidenceBadge.referThreshold;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      _final = await GradeRecordService.save(_final);
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Stone saved - ${_final.stoneId}',
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

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      _final = await GradeRecordService.prepareCertificate(_final);
      Uint8List bytes;
      try {
        bytes = await File(_final.capturedImagePath).readAsBytes();
      } catch (_) {
        bytes = Uint8List(0);
      }
      if (mounted) {
        AppRoutes.push(
            context, CertificateScreen(result: _final, stoneImageBytes: bytes));
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

  @override
  Widget build(BuildContext context) {
    final n = widget.results.length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GemAppBar(
        title: 'Repeatability Summary',
        leading: GemAppBarLeading.back,
        onLeadingPressed: () => CaptureScreen.popTo(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  if (!_consistent) ...[
                    const StatusBanner(
                      type: StatusBannerType.warning,
                      message: 'Inconsistent - gemologist review recommended',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$n captures', style: AppText.titleSmall),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            for (var i = 0; i < n; i++) ...[
                              if (i > 0) const SizedBox(width: AppSpacing.md),
                              Expanded(child: _buildCapture(i)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CardContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
                    child: Column(
                      children: [
                        _buildStatRow(
                          icon: _consistent
                              ? Icons.check_circle_rounded
                              : Icons.warning_rounded,
                          color: _consistent
                              ? AppColors.success
                              : AppColors.warning,
                          tint: _consistent
                              ? AppColors.successTint
                              : AppColors.warningTint,
                          label: 'Agreement',
                          value: Text('$_agree/$n',
                              style: AppText.titleSmall),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _buildStatRow(
                          icon: Icons.difference_outlined,
                          color: AppColors.primary,
                          tint: AppColors.surface,
                          label: 'ΔE₀₀ between captures',
                          // TODO(backend): max ΔE₀₀ between the 3 captures
                          // with its verdict (e.g. "max 0.9 - Excellent").
                          value: Text('-',
                              style: AppText.monoValue.copyWith(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GradeBadgeCard(
                    label: 'FINAL GEMCLOUD GRADE',
                    gradeNumber: _final.gradeNumber,
                    gradeName: _final.gradeName,
                    tradeName: _final.tradeName,
                    chips: [
                      UncertaintyPill(
                        text: _consistent
                            ? 'Agreed $_agree of $n'
                            : _agree > 1
                                ? 'Majority $_agree of $n'
                                : 'No agreement',
                      ),
                      ConfidenceBadge(
                          confidence: _final.confidence, onDark: true),
                    ],
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
                children: _referred
                    ? [
                        PrimaryButton(
                          label: 'Save as Referred',
                          icon: Icons.outgoing_mail,
                          isLoading: _isSaving,
                          onPressed: _save,
                        ),
                        const SizedBox(height: 10),
                        SecondaryButton(
                          label: 'Retake all 3',
                          icon: Icons.photo_camera_rounded,
                          onPressed: _isSaving
                              ? null
                              : () => CaptureScreen.popTo(context),
                        ),
                      ]
                    : [
                        PrimaryButton(
                          label: 'Save & Grade Next',
                          icon: Icons.bookmark_add_rounded,
                          isLoading: _isSaving,
                          onPressed: _isExporting ? null : _save,
                        ),
                        const SizedBox(height: 10),
                        SecondaryButton(
                          label: _isExporting
                              ? 'Preparing...'
                              : 'Export Certificate',
                          icon: Icons.workspace_premium_rounded,
                          onPressed:
                              _isExporting || _isSaving ? null : _export,
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapture(int i) {
    final r = widget.results[i];
    final odd = r.gradeNumber != _finalGrade;
    final rgb = r.measuredRgb;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: odd ? AppColors.warningTint : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: odd ? AppColors.warning : AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, rgb[0], rgb[1], rgb[2]),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Capture ${i + 1}',
              maxLines: 1,
              style: AppText.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Grade ${r.gradeNumber}',
            maxLines: 1,
            style: AppText.sectionHeader.copyWith(
              fontWeight: FontWeight.w700,
              height: 1,
              color: odd ? AppColors.warning : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color color,
    required Color tint,
    required String label,
    required Widget value,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(label,
                style:
                    AppText.body14.copyWith(color: AppColors.textSecondary)),
          ),
          value,
        ],
      ),
    );
  }
}
