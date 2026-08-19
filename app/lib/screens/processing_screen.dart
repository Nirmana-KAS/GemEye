import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';
import 'result_screen.dart';
import '../config/routes.dart';

class ProcessingScreen extends StatefulWidget {
  final String imagePath;
  const ProcessingScreen({super.key, required this.imagePath});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  int _currentStep = 0;
  final List<String> _steps = [
    'Uploading image',
    'Applying colour correction',
    'Segmenting stone',
    'Classifying facet regions',
    'Extracting 12-D features',
    'Running ensemble AI',
    'Generating Grad-CAM',
  ];

  @override
  void initState() {
    super.initState();
    _simulateProcessing();
  }

  void _simulateProcessing() {
    for (int i = 0; i < _steps.length; i++) {
      Timer(Duration(milliseconds: 400 * (i + 1)), () {
        if (mounted) {
          setState(() => _currentStep = i + 1);
          if (i == _steps.length - 1) {
            Timer(const Duration(milliseconds: 500), () {
              if (mounted) {
                AppRoutes.pushReplacement(
                  context,
                  ResultScreen(imagePath: widget.imagePath),
                );
              }
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Lottie.asset(
                    'assets/animations/sapphire_rotate.json',
                    repeat: true,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.diamond_rounded,
                        size: 56,
                        color: GemEyeColors.primary,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Analysing Stone...',
                  style: TextStyle(
                    fontFamily: GemEyeFonts.heading,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: GemEyeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(_steps.length, (index) {
                  final isCompleted = index < _currentStep;
                  final isActive = index == _currentStep;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? GemEyeColors.success
                                : isActive
                                    ? GemEyeColors.primary
                                    : GemEyeColors.border,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                : isActive
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _steps[index],
                          style: TextStyle(
                            fontFamily: GemEyeFonts.body,
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                            color: isCompleted || isActive
                                ? GemEyeColors.textPrimary
                                : GemEyeColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Text(
                  '~${((_steps.length - _currentStep) * 0.4).toStringAsFixed(1)}s remaining',
                  style: const TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 11,
                    color: GemEyeColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
