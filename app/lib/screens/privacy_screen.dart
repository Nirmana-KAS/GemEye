import 'package:flutter/material.dart';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last updated: September 2026',
              style: TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: GemEyeColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              '1. Introduction',
              'GemEye is developed as a final-year research project at NSBM Green University. '
                  'This policy describes how the app collects, uses, and protects your data.',
            ),
            _buildSection(
              '2. Data Collected',
              '• Account information (name, email) via Firebase Authentication\n'
                  '• Gemstone images captured for colour grading\n'
                  '• Grading history and results stored locally on device\n'
                  '• Device calibration data (CCC colour correction matrix)\n'
                  '• Certificate generation records',
            ),
            _buildSection(
              '3. How Data Is Used',
              '• Gemstone images are processed for colour analysis and grading\n'
                  '• Images may be sent to a secure cloud endpoint for AI processing\n'
                  '• Grading results are stored locally for your history\n'
                  '• Account data is used for authentication only',
            ),
            _buildSection(
              '4. Data Storage',
              '• Authentication data: Firebase (Google Cloud, encrypted)\n'
                  '• Grading history: Local device storage (SharedPreferences)\n'
                  '• Certificates: Saved to device Downloads folder\n'
                  '• No data is sold or shared with third parties',
            ),
            _buildSection(
              '5. Data Deletion',
              '• Clear grading history from Settings\n'
                  '• Delete your account from Settings (removes all cloud data)\n'
                  '• Uninstalling the app removes all local data',
            ),
            _buildSection(
              '6. Contact',
              'For questions about this policy, contact:\nshehannirmana.orava@gmail.com',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: GemEyeFonts.heading,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: GemEyeColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 13,
              color: GemEyeColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
