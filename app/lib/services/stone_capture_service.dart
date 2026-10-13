import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';

/// Title of the optional square cropper.
const String kCropTitle = 'Crop Stone Image';

/// Camera / gallery pick and the optional square cropper. The photo is not
/// cropped unless the user asks for it (PhotoPreviewScreen).
class StoneCaptureService {
  /// Returns the picked photo's path, or null when the user cancels.
  /// Throws when the camera or gallery cannot be opened.
  static Future<String?> pick(ImageSource source) async {
    final photo = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 95,
    );
    return photo?.path;
  }

  /// System cropper locked to a square. Returns null when the user cancels.
  /// Throws when the cropper cannot be opened.
  static Future<String?> cropSquare(String sourcePath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: kCropTitle,
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: AppColors.onPrimary,
          activeControlsWidgetColor: AppColors.primary,
          hideBottomControls: false,
          showCropGrid: true,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: kCropTitle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
      ],
    );
    return cropped?.path;
  }
}
