import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_SlideData> _slides = [
    _SlideData(
      icon: Icons.diamond_rounded,
      title: 'Grade Blue Sapphires Instantly',
      description:
          'GemEye uses AI to classify your 1–5 mm blue sapphires into 7 GEMCLOUD colour grades in under 2 seconds. No lab equipment needed.',
    ),
    _SlideData(
      icon: Icons.camera_alt_rounded,
      title: 'What You Need',
      description:
          'An Apexel 100mm macro lens, a CPL filter, a phone tripod, a white gem tray, and the GemEye CCC calibration card.',
    ),
    _SlideData(
      icon: Icons.tune_rounded,
      title: 'Calibrate Once, Grade All Day',
      description:
          'Photograph the CCC card once at the start of each session. GemEye corrects your phone’s colours automatically.',
    ),
    _SlideData(
      icon: Icons.assessment_rounded,
      title: 'Your Grade Report in Seconds',
      description:
          'Get the GEMCLOUD grade, confidence level, Grad-CAM heatmap, and full colour values. Export professional PDF certificates.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    AppRoutes.pushReplacement(context, const MainShell());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GemEyeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: TextButton(
                  onPressed: _navigateToHome,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: GemEyeColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: GemEyeColors.primarySurface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide.icon,
                            size: 40,
                            color: GemEyeColors.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: GemEyeFonts.heading,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: GemEyeColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: GemEyeFonts.body,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: GemEyeColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? GemEyeColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: _currentPage == index
                          ? GemEyeColors.primary
                          : GemEyeColors.border,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _navigateToHome();
                    }
                  },
                  child: Text(
                    _currentPage < _slides.length - 1 ? 'Next' : 'Get Started',
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
}

class _SlideData {
  final IconData icon;
  final String title;
  final String description;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
