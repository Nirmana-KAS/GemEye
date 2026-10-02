import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';

/// A captured and cropped stone photo.
class CapturedStone {
  final String path;

  /// True when the cropper failed and [path] is the uncropped photo.
  final bool cropFailed;

  const CapturedStone(this.path, {this.cropFailed = false});
}

/// Camera / gallery pick followed by the system cropper
/// (crop, rotate, zoom).
class StoneCaptureService {
  /// Returns null when the user cancels the picker or the cropper.
  /// Throws when the camera or gallery cannot be opened.
  static Future<CapturedStone?> pickAndCrop(ImageSource source) async {
    final photo = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 95,
    );
    if (photo == null) return null;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: photo.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Stone Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: AppColors.onPrimary,
            activeControlsWidgetColor: AppColors.primary,
            hideBottomControls: false,
            showCropGrid: true,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Stone Image',
            aspectRatioLockEnabled: false,
          ),
        ],
      );
      if (croppedFile == null) return null;
      return CapturedStone(croppedFile.path);
    } catch (e) {
      debugPrint('Cropper failed: $e');
      return CapturedStone(photo.path, cropFailed: true);
    }
  }
}
