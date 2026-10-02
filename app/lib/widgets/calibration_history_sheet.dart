import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/calibration_service.dart';
import 'app_buttons.dart';
import 'empty_state.dart';

/// Bottom sheet listing saved calibration sessions, newest first. The valid
/// current session is tagged, expired sessions are muted.
class CalibrationHistorySheet extends StatelessWidget {
  /// Called after the sheet closes from the empty-state "Start Calibration".
  final VoidCallback? onStart;

  const CalibrationHistorySheet({super.key, this.onStart});

  static Future<void> show(BuildContext context, {VoidCallback? onStart}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      barrierColor: AppColors.scrim,
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.logo)),
      ),
      builder: (_) => CalibrationHistorySheet(onStart: onStart),
    );
  }

  static String formatWhen(DateTime t) {
    final now = DateTime.now();
    final sameDay =
        t.year == now.year && t.month == now.month && t.day == now.day;
    final time = DateFormat('HH:mm').format(t);
    return sameDay ? 'Today, $time' : '${DateFormat('d MMM').format(t)}, $time';
  }

  static (Color, Color) qualityColors(CalibrationQuality q) => switch (q) {
        CalibrationQuality.excellent => (AppColors.success, AppColors.successTint),
        CalibrationQuality.acceptable => (AppColors.warning, AppColors.warningTint),
        CalibrationQuality.poor => (AppColors.error, AppColors.errorTint),
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calibration history', style: AppText.sectionHeader),
                  SizedBox(height: AppSpacing.xs),
                  Text('Each session is valid for 8 hours',
                      style: AppText.secondary),
                ],
              ),
            ),
            Flexible(
              child: FutureBuilder<List<CalibrationSession>>(
                future: CalibrationService.history(),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox(height: 160);
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) return _buildEmpty(context);
                  final currentId = CalibrationService.session.value?.id;
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final s = items[i];
                      return _SessionRow(
                        session: s,
                        isCurrent: s.id == currentId && s.isValid,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EmptyState(
            icon: Icons.palette_rounded,
            title: 'No calibrations yet',
            message:
                'Calibrate once per session before grading. Past sessions will appear here.',
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Start Calibration',
            onPressed: () {
              Navigator.of(context).pop();
              onStart?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final CalibrationSession session;
  final bool isCurrent;

  const _SessionRow({required this.session, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final expired = !session.isValid;
    final (dot, tint) = CalibrationHistorySheet.qualityColors(session.quality);
    final strong = expired ? AppColors.textMuted : AppColors.textPrimary;
    final soft = expired ? AppColors.textMuted : AppColors.textSecondary;

    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.surface : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        CalibrationHistorySheet.formatWhen(session.createdAt),
                        overflow: TextOverflow.ellipsis,
                        style: AppText.titleSmall.copyWith(color: strong),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        height: 20,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text('Current',
                            style: AppText.button.copyWith(
                                fontSize: 10, color: AppColors.onPrimary)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  expired
                      ? '${session.deviceModel} · expired'
                      : session.deviceModel,
                  style: AppText.secondary.copyWith(color: soft),
                ),
                const SizedBox(height: 3),
                Text(session.id,
                    style: AppText.monoValue
                        .copyWith(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                session.residual.toStringAsFixed(2),
                style: AppText.sectionHeader.copyWith(
                  color: strong,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              QualityChip(
                  quality: session.quality,
                  dot: dot,
                  tint: tint,
                  small: true,
                  muted: expired),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tinted pill with a coloured dot and the quality label.
class QualityChip extends StatelessWidget {
  final CalibrationQuality quality;
  final Color dot;
  final Color tint;
  final bool small;
  final bool muted;

  const QualityChip({
    super.key,
    required this.quality,
    required this.dot,
    required this.tint,
    this.small = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = small ? 20.0 : 24.0;
    return Container(
      height: h,
      padding: EdgeInsets.symmetric(horizontal: small ? AppSpacing.md : 10),
      decoration: BoxDecoration(
        color: muted ? AppColors.surface : tint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: small ? 5 : 6,
            height: small ? 5 : 6,
            decoration: BoxDecoration(
                color: muted ? AppColors.textMuted : dot,
                shape: BoxShape.circle),
          ),
          SizedBox(width: small ? AppSpacing.xs : AppSpacing.sm),
          Text(
            quality.label,
            style: AppText.button.copyWith(
              fontSize: small ? 10 : 12,
              color: muted ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
