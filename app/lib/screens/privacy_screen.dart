import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
                  MarkdownBody(
                    data: snapshot.data ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF6B7089), height: 1.6),
                      h1: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1D2E)),
                      h2: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1D2E)),
                      h3: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1D2E)),
                      strong: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Color(0xFF1A1D2E)),
                      listBullet: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF6B7089)),
                      horizontalRuleDecoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7F0), width: 1))),
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
