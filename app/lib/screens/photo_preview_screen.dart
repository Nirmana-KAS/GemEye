import 'dart:io';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/gem_app_bar.dart';

/// Shown after the camera or gallery: "Use photo" continues to Photo Check
/// with the photo as taken, "Crop (optional)" opens the square cropper and
/// "Retake" picks a new photo.
class PhotoPreviewScreen extends StatelessWidget {
  final String imagePath;
  final void Function(BuildContext context) onUse;
  final void Function(BuildContext context) onCrop;
  final void Function(BuildContext context) onRetake;

  const PhotoPreviewScreen({
    super.key,
    required this.imagePath,
    required this.onUse,
    required this.onCrop,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GemAppBar(
        title: 'Photo Preview',
        leading: GemAppBarLeading.back,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(Icons.broken_image_outlined,
                              size: 48, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'The photo is graded as taken. Cropping is optional - '
                    'keep plenty of white tray around the stone if you crop.',
                    style: AppText.body14.copyWith(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textSecondary),
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
                      label: 'Use photo', onPressed: () => onUse(context)),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: 'Crop (optional)',
                    icon: Icons.crop_rounded,
                    onPressed: () => onCrop(context),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextLinkButton(
                    label: 'Retake',
                    icon: Icons.refresh_rounded,
                    onPressed: () => onRetake(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
