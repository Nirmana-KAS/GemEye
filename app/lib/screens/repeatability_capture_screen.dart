import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/dashed_border.dart';
import '../widgets/gem_app_bar.dart';
import 'capture_screen.dart';
import 'photo_check_screen.dart';

/// Repeatability mode, captures 2 and 3: progress, thumbnails of accepted
/// captures and the capture buttons.
class RepeatabilityCaptureScreen extends StatefulWidget {
  /// Photos already accepted by Photo Check (1 or 2).
  final List<String> acceptedPaths;

  const RepeatabilityCaptureScreen({super.key, required this.acceptedPaths});

  @override
  State<RepeatabilityCaptureScreen> createState() =>
      _RepeatabilityCaptureScreenState();
}

class _RepeatabilityCaptureScreenState
    extends State<RepeatabilityCaptureScreen> {
  ImageSource? _busySource;

  int get _current => widget.acceptedPaths.length;

  Future<void> _capture(ImageSource source) async {
    setState(() => _busySource = source);
    try {
      await PhotoCheckScreen.captureFrom(context, source,
          previousPaths: widget.acceptedPaths, repeatability: true);
    } finally {
      if (mounted) setState(() => _busySource = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _busySource != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GemAppBar(
        title: 'Repeatability Mode',
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
                  _buildProgress(),
                  const SizedBox(height: 10),
                  Text(
                    'Capture ${_current + 1} of $kRepeatabilityCaptures',
                    textAlign: TextAlign.center,
                    style: AppText.sectionHeader,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      for (var i = 0; i < kRepeatabilityCaptures; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildTile(i)),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.back_hand_outlined,
                              size: 22, color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lift and replace the stone, then capture again',
                                style: AppText.sectionHeader
                                    .copyWith(height: 1.35),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Keep the same lighting and camera settings.',
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
                    label: 'Import from Gallery',
                    icon: Icons.photo_library_rounded,
                    isLoading: _busySource == ImageSource.gallery,
                    onPressed:
                        busy ? null : () => _capture(ImageSource.gallery),
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: 'Take Photo',
                    icon: Icons.photo_camera_rounded,
                    onPressed: busy ? null : () => _capture(ImageSource.camera),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final children = <Widget>[];
    for (var i = 0; i < kRepeatabilityCaptures; i++) {
      if (i > 0) {
        children.add(Container(
          width: 32,
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          color: i <= _current ? AppColors.success : AppColors.border,
        ));
      }
      final Widget dot;
      if (i < _current) {
        dot = Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
              color: AppColors.success, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded,
              size: 16, color: AppColors.onPrimary),
        );
      } else if (i == _current) {
        dot = Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.surface, spreadRadius: 4)],
          ),
          child: Text('${i + 1}',
              style: AppText.button
                  .copyWith(fontSize: 11, color: AppColors.onPrimary)),
        );
      } else {
        dot = Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Text('${i + 1}',
              style: AppText.button
                  .copyWith(fontSize: 11, color: AppColors.textMuted)),
        );
      }
      children.add(dot);
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: children),
    );
  }

  Widget _buildTile(int i) {
    final Widget box;
    final String label;
    final TextStyle style;
    if (i < _current) {
      label = '${i + 1} · Done';
      style = AppText.secondary
          .copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimary);
      box = Stack(
        fit: StackFit.expand,
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Image.file(
              File(widget.acceptedPaths[i]),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_outlined, color: AppColors.textMuted),
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  size: 14, color: AppColors.onPrimary),
            ),
          ),
        ],
      );
    } else if (i == _current) {
      label = '${i + 1} · Now';
      style = AppText.button.copyWith(fontSize: 12, color: AppColors.primary);
      box = CustomPaint(
        painter: const DashedBorderPainter(
            color: AppColors.primary, radius: AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(Icons.add_a_photo_outlined,
              size: 28, color: AppColors.primary),
        ),
      );
    } else {
      label = '${i + 1} · Pending';
      style = AppText.secondary;
      box = Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.image_outlined,
            size: 24, color: AppColors.textMuted),
      );
    }
    return Column(
      children: [
        AspectRatio(aspectRatio: 1, child: box),
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: style),
      ],
    );
  }
}
