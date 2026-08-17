import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';
import '../config/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      // TODO: Navigate to agreement/login/home based on auth state
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                'assets/animations/sapphire_rotate.json',
                repeat: true,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: GemEyeColors.primarySurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: GemEyeColors.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.diamond_rounded,
                      size: 48,
                      color: GemEyeColors.primary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: GemEyeColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppConstants.appTagline,
              style: TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 12,
                color: GemEyeColors.textMuted,
              ),
            ),
            const SizedBox(height: 60),
            Text(
              'v${AppConstants.appVersion} · ${AppConstants.appYear}',
              style: const TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 10,
                color: GemEyeColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}