import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import 'processing_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  bool _isCapturing = false;

  Future<void> _captureImage() async {
    setState(() => _isCapturing = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );

      if (photo == null) {
        setState(() => _isCapturing = false);
        return;
      }

      await _cropAndProceed(photo.path);
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: ${e.toString()}'),
            backgroundColor: GemEyeColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isCapturing = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );

      if (photo == null) {
        setState(() => _isCapturing = false);
        return;
      }

      await _cropAndProceed(photo.path);
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery error: ${e.toString()}'),
            backgroundColor: GemEyeColors.error,
          ),
        );
      }
    }
  }

  Future<void> _cropAndProceed(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Stone Image',
            toolbarColor: const Color(0xFF1B3A8C),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF1B3A8C),
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

      setState(() => _isCapturing = false);

      if (croppedFile != null && mounted) {
        AppRoutes.push(context, ProcessingScreen(imagePath: croppedFile.path));
      }
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crop unavailable — using original image'),
            backgroundColor: GemEyeColors.warning,
          ),
        );
        AppRoutes.push(context, ProcessingScreen(imagePath: imagePath));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Grade Stone'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Capture Your Sapphire',
                        style: TextStyle(
                          fontFamily: GemEyeFonts.heading,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: GemEyeColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Place stone face-up on white tray. Take photo\nwith macro lens. Crop after capture.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: GemEyeFonts.body,
                          fontSize: 12,
                          color: GemEyeColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          border: Border.all(color: GemEyeColors.primary, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: GemEyeColors.primary, width: 2),
                                    left: BorderSide(color: GemEyeColors.primary, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: GemEyeColors.primary, width: 2),
                                    right: BorderSide(color: GemEyeColors.primary, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              left: 6,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: GemEyeColors.primary, width: 2),
                                    left: BorderSide(color: GemEyeColors.primary, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: GemEyeColors.primary, width: 2),
                                    right: BorderSide(color: GemEyeColors.primary, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: GemEyeColors.success, width: 2),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.diamond_outlined,
                                  size: 22,
                                  color: GemEyeColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Zoom until stone fills the circle',
                        style: TextStyle(
                          fontFamily: GemEyeFonts.heading,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: GemEyeColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Stone should be ~70% of the frame for best results',
                        style: TextStyle(
                          fontFamily: GemEyeFonts.body,
                          fontSize: 10,
                          color: GemEyeColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCheckItem('Macro lens attached'),
                            _buildCheckItem('CPL filter on'),
                            _buildCheckItem('Stone on white tray'),
                            _buildCheckItem('Even lighting'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: _isCapturing
                  ? const Center(child: CircularProgressIndicator(color: GemEyeColors.primary))
                  : Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _captureImage,
                            icon: const Icon(Icons.camera_alt_rounded, size: 22),
                            label: const Text(
                              'Take Photo',
                              style: TextStyle(
                                fontFamily: GemEyeFonts.heading,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _pickFromGallery,
                            icon: const Icon(Icons.photo_library_rounded, size: 20),
                            label: const Text(
                              'Choose from Gallery',
                              style: TextStyle(
                                fontFamily: GemEyeFonts.heading,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: GemEyeColors.success, size: 22),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 14,
              color: GemEyeColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
