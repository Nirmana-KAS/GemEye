import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../config/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GemEyeColors.background,
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Image.asset('assets/images/logo.png', width: 80, height: 80),
            const SizedBox(height: 16),
            const Text(
              'GemEye',
              style: TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: GemEyeColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'v${AppConstants.appVersion} - September ${AppConstants.appYear}',
              style: TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 14,
                color: GemEyeColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Automated Blue Sapphire Colour Grading',
              style: TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 14,
                color: GemEyeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'A smartphone-based automated colour grading system for 1-5 mm cut and polished blue sapphires, using the GEMCLOUD 7-grade standard, device-independent CCC calibration, and ensemble machine learning.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 12,
                  color: GemEyeColors.textMuted,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'Developer',
              style: TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: GemEyeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const CircleAvatar(
              radius: 32,
              backgroundColor: GemEyeColors.primarySurface,
              child: Icon(Icons.person, size: 32, color: GemEyeColors.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nirmana K.A.S.',
              style: TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: GemEyeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'BSc (Hons) Computer Science - Final Year',
              style: TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 13,
                color: GemEyeColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (AppConstants.linkedInUrl.isNotEmpty) {
                      _launchUrl(AppConstants.linkedInUrl);
                    }
                  },
                  icon: const Icon(Icons.link, color: GemEyeColors.primary),
                  tooltip: 'LinkedIn',
                ),
                IconButton(
                  onPressed: () {
                    if (AppConstants.githubUrl.isNotEmpty) {
                      _launchUrl(AppConstants.githubUrl);
                    }
                  },
                  icon: const Icon(Icons.code, color: GemEyeColors.primary),
                  tooltip: 'GitHub',
                ),
                IconButton(
                  onPressed: () {
                    if (AppConstants.emailAddress.isNotEmpty) {
                      _launchUrl('mailto:${AppConstants.emailAddress}');
                    }
                  },
                  icon: const Icon(Icons.email, color: GemEyeColors.primary),
                  tooltip: 'Email',
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'Academic Support',
              style: TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: GemEyeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'NSBM Green University',
              style: TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 13,
                color: GemEyeColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            _buildPersonCard('Supervisor Name', 'Designation'),
            const SizedBox(height: 8),
            _buildPersonCard('Supervisor Name', 'Designation'),
            const SizedBox(height: 8),
            _buildPersonCard('Supervisor Name', 'Designation'),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'Industry Partner',
              style: TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: GemEyeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Orava (Pvt) Ltd.',
              style: TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 13,
                color: GemEyeColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            _buildPersonCard('Supervisor Name', 'Designation'),
            const SizedBox(height: 8),
            _buildPersonCard('Supervisor Name', 'Designation'),
            const SizedBox(height: 8),
            _buildPersonCard('Supervisor Name', 'Designation'),

            const SizedBox(height: 24),
            const Text(
              'Made with care in Sri Lanka',
              style: TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 12,
                color: GemEyeColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '${AppConstants.appYear} ${AppConstants.developerName}',
              style: TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 11,
                color: GemEyeColors.textMuted,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCard(String name, String designation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GemEyeColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GemEyeColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: GemEyeColors.primarySurface,
            child: Icon(Icons.person, color: GemEyeColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              Text(
                designation,
                style: const TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 12,
                  color: GemEyeColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
