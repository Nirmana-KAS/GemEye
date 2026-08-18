import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../config/routes.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return Scaffold(
      backgroundColor: GemEyeColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.diamond_rounded,
                  size: 64, color: GemEyeColors.primary),
              const SizedBox(height: 16),
              Text(
                'Welcome, ${authService.getFirstName()}!',
                style: const TextStyle(
                  fontFamily: GemEyeFonts.heading,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Home screen coming soon...',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  color: GemEyeColors.textMuted,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    AppRoutes.pushReplacement(context, const LoginScreen());
                  }
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
