import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  List<Map<String, dynamic>> _grades = [];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    final jsonStr = await rootBundle.loadString('assets/data/colour_grades.json');
    final List<dynamic> data = jsonDecode(jsonStr);
    setState(() {
      _grades = data.cast<Map<String, dynamic>>();
    });
  }

  Color _parseHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF091A47),
                  Color(0xFF102670),
                  Color(0xFF1B3A8C),
                  Color(0xFF2E5BB8),
                  Color(0xFF4A80D4),
                  Color(0xFF7BA7E8),
                  Color(0xFFA8C8F0),
                  Color(0xFFD6E5F8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) => Text(
                'G${i + 1}',
                style: const TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 10,
                  color: GemEyeColors.textMuted,
                ),
              )),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '7 GEMCLOUD Colour Grades',
              style: TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: GemEyeColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tap any grade to see details',
              style: TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 12,
                color: GemEyeColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_grades.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: GemEyeColors.primary),
              ),
            )
          else
            ..._grades.map((grade) => _buildGradeCard(grade)),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Based on GEMCLOUD 7-Grade Standard, GRS, Bellerophon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: GemEyeColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGradeCard(Map<String, dynamic> grade) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Card(
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  _parseHex(grade['colourStart']),
                  _parseHex(grade['colourEnd']),
                ],
              ),
            ),
          ),
          title: Text(
            'Grade ${grade['grade']} - ${grade['name']}',
            style: const TextStyle(
              fontFamily: GemEyeFonts.heading,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: GemEyeColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Trade: ${grade['tradeName']}',
            style: const TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 12,
              color: GemEyeColors.textMuted,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: GemEyeColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    grade['description'],
                    style: const TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 12,
                      color: GemEyeColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildInfoChip('Hue: ${grade['hueRange']}'),
                      _buildInfoChip('Sat: ${grade['satRange']}'),
                      _buildInfoChip('Brt: ${grade['brtRange']}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildInfoChip('L*: ${grade['labL']}'),
                      _buildInfoChip('b*: ${grade['labB']}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: GemEyeFonts.mono,
          fontSize: 11,
          color: GemEyeColors.textSecondary,
        ),
      ),
    );
  }
}
