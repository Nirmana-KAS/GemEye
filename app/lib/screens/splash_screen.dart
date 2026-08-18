import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../config/routes.dart';
import '../services/auth_service.dart';
import 'agreement_screen.dart';
import 'main_shell.dart';

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
      if (!mounted) return;
      final authService = AuthService();
      if (authService.isLoggedIn) {
        AppRoutes.pushReplacement(context, const MainShell());
      } else {
        AppRoutes.pushReplacement(context, const AgreementScreen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              const Spacer(flex: 3),
              Center(
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: Lottie.asset(
                    'assets/animations/sapphire_rotate.json',
                    repeat: true,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: GemEyeColors.primarySurface,
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(
                            color: GemEyeColors.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.diamond_rounded,
                          size: 56,
                          color: GemEyeColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: GemEyeFonts.heading,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: GemEyeColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  AppConstants.appTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: GemEyeColors.textMuted,
                  ),
                ),
              ),
              const Spacer(flex: 4),
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text(
                    'v${AppConstants.appVersion} · ${AppConstants.appYear}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: GemEyeColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
