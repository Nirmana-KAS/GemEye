import 'dart:io';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class ResultScreen extends StatelessWidget {
  final String imagePath;
  const ResultScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Grading Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              // TODO: Share result
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Stone image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(imagePath),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: GemEyeColors.primarySurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.diamond_rounded, size: 48, color: GemEyeColors.textMuted),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Grade badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF091A72), Color(0xFF1B3A8C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'GEMCLOUD GRADE',
                      style: TextStyle(
                        fontFamily: GemEyeFonts.body,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Grade 3',
                      style: TextStyle(
                        fontFamily: GemEyeFonts.heading,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Vivid — Royal Blue',
                      style: TextStyle(
                        fontFamily: GemEyeFonts.heading,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '± 0.2 grades',
                        style: TextStyle(
                          fontFamily: GemEyeFonts.mono,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: GemEyeColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'HIGH CONFIDENCE',
                        style: TextStyle(
                          fontFamily: GemEyeFonts.body,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Colour values
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: GemEyeColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COLOUR VALUES',
                      style: TextStyle(
                        fontFamily: GemEyeFonts.body,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: GemEyeColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildValueRow('L*', '42.3', 'a*', '8.9'),
                    const SizedBox(height: 8),
                    _buildValueRow('b*', '-27.0', 'C*', '28.4'),
                    const SizedBox(height: 8),
                    _buildValueRow('Hue', '228°', 'Sat', '88%'),
                    const SizedBox(height: 8),
                    _buildValueRow('Brt', '62%', 'ΔE₀₀', '1.2'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Grad-CAM placeholder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: GemEyeColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GRAD-CAM HEATMAP',
                      style: TextStyle(
                        fontFamily: GemEyeFonts.body,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: GemEyeColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const RadialGradient(
                          center: Alignment(-0.1, 0.0),
                          colors: [
                            Color(0x99EF4444),
                            Color(0x66F59E0B),
                            Color(0x3310B981),
                            Color(0x331B3A8C),
                          ],
                          stops: [0.0, 0.3, 0.6, 1.0],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Heatmap will appear here',
                          style: TextStyle(
                            fontFamily: GemEyeFonts.body,
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Red = high influence on prediction · Blue = low influence',
                      style: TextStyle(
                        fontFamily: GemEyeFonts.body,
                        fontSize: 10,
                        color: GemEyeColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        child: const Text('Save & Grade Next'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Export certificate
                        },
                        child: const Text('Export Certificate'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: GemEyeColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label1,
                  style: const TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 12,
                    color: GemEyeColors.textSecondary,
                  ),
                ),
                Text(
                  value1,
                  style: const TextStyle(
                    fontFamily: GemEyeFonts.mono,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GemEyeColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: GemEyeColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label2,
                  style: const TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 12,
                    color: GemEyeColors.textSecondary,
                  ),
                ),
                Text(
                  value2,
                  style: const TextStyle(
                    fontFamily: GemEyeFonts.mono,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GemEyeColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
