import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.darkIcons,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Lottie.asset(
                          'assets/animations/sapphire_rotate.json',
                          repeat: true,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.logo),
                              child: Image.asset('assets/images/logo.png'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      const Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: AppText.display,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        AppConstants.appTagline,
                        textAlign: TextAlign.center,
                        style: AppText.secondary
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.huge),
                child: Text(
                  'v${AppConstants.appVersion} · ${AppConstants.appYear}',
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
