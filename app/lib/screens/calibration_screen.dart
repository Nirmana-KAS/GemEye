import 'package:flutter/material.dart';
import '../config/theme.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Calibrate Device'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: index <= _currentStep
                                  ? GemEyeColors.primary
                                  : GemEyeColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (index < 2) const SizedBox(width: 6),
                      ],
                    ),
                  );
                }),
              ),
            ),
            // Step label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Step ${_currentStep + 1} of 3',
                  style: const TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 13,
                    color: GemEyeColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Step content
            Expanded(
              child: _buildStepContent(),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentStep < 2) {
                      setState(() => _currentStep++);
                    } else {
                      _completeCalibration();
                    }
                  },
                  child: Text(
                    _currentStep < 2 ? 'Next' : 'Complete Calibration',
                    style: const TextStyle(
                      fontFamily: GemEyeFonts.heading,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: GemEyeColors.primarySurface,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.grid_view_rounded, size: 48, color: GemEyeColors.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Place CCC Card',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GemEyeFonts.heading,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: GemEyeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Place the 6-patch Colour Calibration Card (CCC) on a flat surface under your current lighting conditions. Make sure all 6 colour patches are clean and visible.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 14,
              color: GemEyeColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GemEyeColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GemEyeColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CCC Card Patches:',
                  style: TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: GemEyeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPatchPreview('White', const Color(0xFFF0F0F0)),
                    _buildPatchPreview('18% Grey', const Color(0xFF767676)),
                    _buildPatchPreview('Blue', const Color(0xFF004D8D)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPatchPreview('Black', const Color(0xFF101010)),
                    _buildPatchPreview('50% Grey', const Color(0xFFB5B5B5)),
                    _buildPatchPreview('Red', const Color(0xFF95444F)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: GemEyeColors.primarySurface,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.phone_android_rounded, size: 48, color: GemEyeColors.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mount Phone on Tripod',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GemEyeFonts.heading,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: GemEyeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mount your phone on the tripod pointing straight down at the CCC card. Attach the Apexel 100mm macro lens and CPL filter. Make sure the phone is stable and all 6 patches are visible in the camera view.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 14,
              color: GemEyeColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GemEyeColors.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 20, color: Color(0xFF92400E)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tip: Make sure the lighting is even across all patches. Avoid direct sunlight or harsh shadows.',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 12,
                      color: Color(0xFF92400E),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: GemEyeColors.primarySurface,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.camera_alt_rounded, size: 48, color: GemEyeColors.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Capture CCC Card',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GemEyeFonts.heading,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: GemEyeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Take a photo of the CCC card. The system will detect all 6 patches and compute your device\'s colour correction matrix automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 14,
              color: GemEyeColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Simulated viewfinder
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Patch grid preview
                  SizedBox(
                    width: 160,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildViewfinderPatch(const Color(0xFFF0F0F0)),
                            _buildViewfinderPatch(const Color(0xFF767676)),
                            _buildViewfinderPatch(const Color(0xFF004D8D)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildViewfinderPatch(const Color(0xFF101010)),
                            _buildViewfinderPatch(const Color(0xFFB5B5B5)),
                            _buildViewfinderPatch(const Color(0xFF95444F)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap "Complete Calibration" to capture',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GemEyeColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GemEyeColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: GemEyeColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Calibration is valid for this entire session. Recalibrate if you change lighting or device.',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 11,
                      color: GemEyeColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatchPreview(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: GemEyeColors.border, width: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: GemEyeFonts.body,
            fontSize: 9,
            color: GemEyeColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildViewfinderPatch(Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: GemEyeColors.success, width: 1.5),
      ),
    );
  }

  void _completeCalibration() {
    // TODO: Implement actual camera capture and CCC processing
    // For now, show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: GemEyeColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.check_circle_rounded, size: 40, color: GemEyeColors.success),
            ),
            const SizedBox(height: 16),
            const Text(
              'Calibration Complete',
              style: TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GemEyeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Residual ΔE: 1.4 (excellent)\nYour device is ready for grading.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 13,
                color: GemEyeColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to home
              },
              child: const Text('Start Grading'),
            ),
          ),
        ],
      ),
    );
  }
}
