import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_client.dart';
import '../services/heatmap_service.dart';
import 'app_buttons.dart';
import 'loading_indicator.dart';

/// Loads the heatmap of one grading; [HeatmapService.fetch] by default.
typedef HeatmapLoader = Future<HeatmapImage> Function(String gradingId);

/// Grad-CAM heatmap section of the Grade Result screen. Hidden when
/// features.gradcam is off; otherwise loads the heatmap from the server
/// (spinner, then the image, or an error with Retry).
class GradCamCard extends StatefulWidget {
  /// Server grading id; null for a result that was never saved on the server.
  final String? gradingId;
  final bool enabled;
  final HeatmapLoader? loader;

  const GradCamCard({
    super.key,
    required this.gradingId,
    required this.enabled,
    this.loader,
  });

  static const String legend =
      'Red = high influence on prediction, Blue = low influence';
  static const String explanation =
      'Shows where the CNN looked. It is an explanation aid, not a second '
      'opinion.';
  static const String unavailable = 'Heatmap not available for this grading';

  @override
  State<GradCamCard> createState() => _GradCamCardState();
}

class _GradCamCardState extends State<GradCamCard> {
  Future<HeatmapImage>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(GradCamCard old) {
    super.didUpdateWidget(old);
    if (old.gradingId != widget.gradingId || old.enabled != widget.enabled) {
      _load();
    }
  }

  void _load() {
    final id = widget.gradingId;
    _future = widget.enabled && id != null
        ? (widget.loader ?? HeatmapService.fetch)(id)
        : null;
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _future == null
              ? _message(GradCamCard.unavailable)
              : FutureBuilder<HeatmapImage>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return _frame(const Center(
                          key: Key('gradcam_loading'),
                          child: LoadingIndicator(size: 24)));
                    }
                    if (snap.hasError || !snap.hasData) {
                      return _error(snap.error);
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        snap.data!.bytes,
                        key: const Key('gradcam_image'),
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) =>
                            _message(GradCamCard.unavailable),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 8),
          const Text(
            GradCamCard.legend,
            style: TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            GradCamCard.explanation,
            style: TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _frame(Widget child) => Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      );

  Widget _message(String text) => _frame(Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ));

  Widget _error(Object? error) {
    final message = switch (error) {
      ApiException(code: ApiErrorCode.notFound) => GradCamCard.unavailable,
      ApiException(:final message) => message,
      _ => 'The heatmap could not be loaded. Please try again.',
    };
    if (error is! ApiException && error != null) {
      debugPrint('Heatmap failed: $error');
    }
    return _frame(Column(
      key: const Key('gradcam_error'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.textMuted, size: 22),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextLinkButton(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: _retry,
        ),
      ],
    ));
  }
}
