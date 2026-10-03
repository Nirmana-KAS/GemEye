import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import 'app_buttons.dart';
import 'app_snack_bar.dart';

enum ImagePickerShape { circle, roundedSquare }

/// Optional image picker row. Circle = profile photo (shows the initial
/// letter when empty), rounded square = company logo (shows an upload icon).
class ImagePickerField extends StatelessWidget {
  static const int maxBytes = 5 * 1024 * 1024;

  final String label;
  final ImagePickerShape shape;
  final File? image;
  final String initialLetter;
  final String pickLabel;
  final IconData pickIcon;
  final ValueChanged<File?> onChanged;

  const ImagePickerField({
    super.key,
    required this.label,
    required this.image,
    required this.onChanged,
    this.shape = ImagePickerShape.circle,
    this.initialLetter = '',
    this.pickLabel = 'Upload photo',
    this.pickIcon = Icons.photo_camera_rounded,
  });

  Future<void> _pick(BuildContext context) async {
    final file = await pickImage(context);
    if (file != null) onChanged(file);
  }

  /// Gallery picker with the JPG / PNG and 5 MB checks. Returns null when
  /// cancelled or rejected (the reason is shown in a snackbar).
  static Future<File?> pickImage(BuildContext context) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return null;
      final name = picked.name.toLowerCase();
      final validType = name.endsWith('.jpg') ||
          name.endsWith('.jpeg') ||
          name.endsWith('.png');
      if (!validType) {
        if (context.mounted) {
          AppSnackBar.show(context,
              message: 'Choose a JPG or PNG image',
              type: AppSnackBarType.error);
        }
        return null;
      }
      if (await picked.length() > maxBytes) {
        if (context.mounted) {
          AppSnackBar.show(context,
              message: 'Image is larger than 5 MB',
              type: AppSnackBarType.error);
        }
        return null;
      }
      return File(picked.path);
    } catch (e) {
      if (kDebugMode) debugPrint('ImagePickerField: $e');
      if (context.mounted) {
        AppSnackBar.show(context,
            message: 'Could not open your photos. Please try again.',
            type: AppSnackBarType.error);
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCircle = shape == ImagePickerShape.circle;
    final radius = isCircle
        ? BorderRadius.circular(32)
        : BorderRadius.circular(AppRadius.xl);
    final hasImage = image != null;

    Widget preview;
    if (hasImage) {
      preview = Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Image.file(image!, width: 64, height: 64, fit: BoxFit.cover),
        ),
      );
    } else if (isCircle) {
      final letter = initialLetter.trim().isEmpty
          ? '?'
          : initialLetter.trim()[0].toUpperCase();
      preview = Container(
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: AppText.screenTitle
              .copyWith(fontSize: 26, color: AppColors.onPrimary),
        ),
      );
    } else {
      preview = CustomPaint(
        foregroundPainter: _DashedBorderPainter(radius: AppRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: radius,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.upload_rounded,
              size: 26, color: AppColors.primary),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(width: 64, height: 64, child: preview),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(TextSpan(
                text: label,
                style: AppText.body14Medium,
                children: [
                  TextSpan(
                    text: ' · Optional',
                    style:
                        AppText.secondary.copyWith(color: AppColors.textMuted),
                  ),
                ],
              )),
              Transform.translate(
                offset: const Offset(-AppSpacing.md, 0),
                child: hasImage
                    ? TextLinkButton(
                        label: 'Remove',
                        icon: Icons.delete_rounded,
                        onPressed: () => onChanged(null),
                      )
                    : TextLinkButton(
                        label: pickLabel,
                        icon: pickIcon,
                        onPressed: () => _pick(context),
                      ),
              ),
              const Text('JPG or PNG · up to 5 MB', style: AppText.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double radius;

  _DashedBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(0.75);
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
