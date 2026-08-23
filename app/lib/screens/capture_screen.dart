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
            showCropGrid: true,
            lockAspectRatio: false,
            hideBottomControls: true,
            initAspectRatio: CropAspectRatioPreset.square,
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
            backgroundColor: Color(0xFFF59E0B),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Instructions area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: GemEyeColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GemEyeColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: GemEyeColors.border),
                      ),
                      child: const Icon(Icons.diamond_rounded, size: 40, color: GemEyeColors.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Capture Your Sapphire',
                      style: TextStyle(
                        fontFamily: GemEyeFonts.heading,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: GemEyeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Place the stone face-up on the white gem tray. Take a photo with the macro lens attached. You can crop the image after capture.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: GemEyeFonts.body,
                        fontSize: 13,
                        color: GemEyeColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Checklist
              _buildCheckItem(Icons.check_circle_rounded, 'Macro lens attached', true),
              const SizedBox(height: 8),
              _buildCheckItem(Icons.check_circle_rounded, 'CPL filter on', true),
              const SizedBox(height: 8),
              _buildCheckItem(Icons.check_circle_rounded, 'Stone on white tray', true),
              const SizedBox(height: 8),
              _buildCheckItem(Icons.check_circle_rounded, 'Even lighting', true),
              const Spacer(flex: 3),
              // Capture buttons
              if (_isCapturing)
                const Center(child: CircularProgressIndicator(color: GemEyeColors.primary))
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library_rounded, size: 20),
                        label: const Text(
                          'Choose from Gallery',
                          style: TextStyle(
                            fontFamily: GemEyeFonts.heading,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(IconData icon, String text, bool checked) {
    return Row(
      children: [
        Icon(
          checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: checked ? GemEyeColors.success : GemEyeColors.textMuted,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontFamily: GemEyeFonts.body,
            fontSize: 13,
            color: checked ? GemEyeColors.textPrimary : GemEyeColors.textMuted,
          ),
        ),
      ],
    );
  }
}
