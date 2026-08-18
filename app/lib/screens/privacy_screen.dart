import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GemEyeColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: rootBundle.loadString('assets/data/privacy_policy.md'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: GemEyeColors.primary,
                ),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Unable to load privacy policy.',
                  style: TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 14,
                    color: GemEyeColors.textSecondary,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last updated: August 2026',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: GemEyeColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.data ?? '',
                    style: const TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: GemEyeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
