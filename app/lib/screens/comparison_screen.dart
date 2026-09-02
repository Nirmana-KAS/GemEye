import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/grade_result.dart';
import '../services/storage_service.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  GradeResult? _stoneA;
  GradeResult? _stoneB;

  static const Map<int, Color> gradeColors = {
    1: Color(0xFF091A47),
    2: Color(0xFF102670),
    3: Color(0xFF1B3A8C),
    4: Color(0xFF2E5BB8),
    5: Color(0xFF4A80D4),
    6: Color(0xFF7BA7E8),
    7: Color(0xFFA8C8F0),
  };

  Future<void> _pickStone(bool isA) async {
    final history = await StorageService.getGradeHistory();
    if (!mounted) return;

    final picked = await showModalBottomSheet<GradeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select Stone ${isA ? 'A' : 'B'}',
                    style: const TextStyle(
                      fontFamily: GemEyeFonts.heading,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: GemEyeColors.textPrimary,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: history.isEmpty
                      ? const Center(
                          child: Text(
                            'No stones available',
                            style: TextStyle(
                              fontFamily: GemEyeFonts.body,
                              fontSize: 14,
                              color: GemEyeColors.textMuted,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: history.length,
                          itemBuilder: (ctx, i) {
                            final r = history[i];
                            final color = gradeColors[r.gradeNumber] ?? GemEyeColors.primary;
                            return ListTile(
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                'Grade ${r.gradeNumber} - ${r.tradeName}',
                                style: const TextStyle(
                                  fontFamily: GemEyeFonts.body,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: GemEyeColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                r.stoneId,
                                style: const TextStyle(
                                  fontFamily: GemEyeFonts.body,
                                  fontSize: 11,
                                  color: GemEyeColors.textMuted,
                                ),
                              ),
                              onTap: () => Navigator.pop(ctx, r),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isA) {
          _stoneA = picked;
        } else {
          _stoneB = picked;
        }
      });
    }
  }

  double _calculateDeltaE(GradeResult a, GradeResult b) {
    return sqrt(
      pow(a.labL - b.labL, 2) +
      pow(a.labA - b.labA, 2) +
      pow(a.labB - b.labB, 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Stone Comparison')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Selection cards
              Row(
                children: [
                  Expanded(child: _buildSelectionCard(true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSelectionCard(false)),
                ],
              ),
              const SizedBox(height: 24),

              if (_stoneA != null && _stoneB != null) ...[
                _buildComparisonBody(),
              ] else
                _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard(bool isA) {
    final stone = isA ? _stoneA : _stoneB;
    final label = isA ? 'A' : 'B';

    return GestureDetector(
      onTap: () => _pickStone(isA),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: stone != null ? GemEyeColors.border : GemEyeColors.textMuted,
            width: 1,
            style: stone != null ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        foregroundDecoration: stone == null
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: GemEyeColors.textMuted, width: 1),
              )
            : null,
        child: stone != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: gradeColors[stone.gradeNumber] ?? GemEyeColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Grade ${stone.gradeNumber}',
                    style: const TextStyle(
                      fontFamily: GemEyeFonts.heading,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: GemEyeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stone.stoneId,
                    style: const TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 11,
                      color: GemEyeColors.textMuted,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, size: 28, color: GemEyeColors.textMuted),
                  const SizedBox(height: 4),
                  Text(
                    'Select Stone $label',
                    style: const TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 13,
                      color: GemEyeColors.textMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildComparisonBody() {
    final a = _stoneA!;
    final b = _stoneB!;
    final deltaE = _calculateDeltaE(a, b);
    final gradesDiff = (a.gradeNumber - b.gradeNumber).abs();

    Color deltaColor;
    String deltaLabel;
    if (deltaE < 2.0) {
      deltaColor = GemEyeColors.success;
      deltaLabel = 'Visually similar';
    } else if (deltaE <= 5.0) {
      deltaColor = GemEyeColors.warning;
      deltaLabel = 'Noticeable difference';
    } else {
      deltaColor = GemEyeColors.error;
      deltaLabel = 'Significantly different';
    }

    return Column(
      children: [
        // Side-by-side images
        Row(
          children: [
            Expanded(child: _buildStoneImage(a)),
            const SizedBox(width: 12),
            Expanded(child: _buildStoneImage(b)),
          ],
        ),
        const SizedBox(height: 16),

        // Delta E card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: deltaColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: deltaColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                'ΔE = ${deltaE.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: GemEyeFonts.mono,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: deltaColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                deltaLabel,
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: deltaColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Text(
          '$gradesDiff grade${gradesDiff != 1 ? 's' : ''} apart',
          style: const TextStyle(
            fontFamily: GemEyeFonts.body,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: GemEyeColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Value comparison table
        _buildComparisonTable(a, b),
        const SizedBox(height: 20),

        // Swap button
        TextButton.icon(
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('Swap A ↔ B'),
          onPressed: () {
            setState(() {
              final temp = _stoneA;
              _stoneA = _stoneB;
              _stoneB = temp;
            });
          },
        ),
        const SizedBox(height: 8),

        // Compare another
        OutlinedButton(
          onPressed: () {
            setState(() {
              _stoneA = null;
              _stoneB = null;
            });
          },
          child: const Text('Compare Another'),
        ),
      ],
    );
  }

  Widget _buildStoneImage(GradeResult result) {
    final gradeColor = gradeColors[result.gradeNumber] ?? GemEyeColors.primary;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(result.capturedImagePath),
            width: double.infinity,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: GemEyeColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.diamond_rounded, size: 36, color: GemEyeColors.textMuted),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: gradeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Grade ${result.gradeNumber}',
            style: const TextStyle(
              fontFamily: GemEyeFonts.heading,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonTable(GradeResult a, GradeResult b) {
    final rows = [
      _ComparisonRow('Lightness', a.labL, b.labL),
      _ComparisonRow('Green-Red', a.labA, b.labA),
      _ComparisonRow('Blue-Yellow', a.labB, b.labB),
      _ComparisonRow('Chroma', a.labC, b.labC),
      _ComparisonRow('Hue', a.hue, b.hue),
      _ComparisonRow('Saturation', a.saturation, b.saturation),
      _ComparisonRow('Brightness', a.brightness, b.brightness),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GemEyeColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.2),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: GemEyeColors.primarySurface),
              children: [
                _tableHeader('Metric'),
                _tableHeader('Stone A'),
                _tableHeader('Stone B'),
                _tableHeader('Diff'),
              ],
            ),
            ...rows.map((r) {
              final diff = (r.valueA - r.valueB).abs();
              Color diffColor;
              if (diff < 1.0) {
                diffColor = GemEyeColors.success;
              } else if (diff <= 3.0) {
                diffColor = GemEyeColors.warning;
              } else {
                diffColor = GemEyeColors.error;
              }
              return TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: GemEyeColors.border, width: 0.5)),
                ),
                children: [
                  _tableCell(r.label, isLabel: true),
                  _tableCell(r.valueA.toStringAsFixed(1)),
                  _tableCell(r.valueB.toStringAsFixed(1)),
                  _tableDiffCell(diff.toStringAsFixed(1), diffColor),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: GemEyeFonts.body,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: GemEyeColors.primary,
        ),
      ),
    );
  }

  Widget _tableCell(String text, {bool isLabel = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: isLabel ? GemEyeFonts.body : GemEyeFonts.mono,
          fontSize: 12,
          fontWeight: isLabel ? FontWeight.w400 : FontWeight.w400,
          color: isLabel ? GemEyeColors.textSecondary : GemEyeColors.textPrimary,
        ),
      ),
    );
  }

  Widget _tableDiffCell(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: GemEyeFonts.mono,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(Icons.compare_arrows_rounded, size: 64, color: GemEyeColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'Select two stones to compare',
            style: TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 14,
              color: GemEyeColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow {
  final String label;
  final double valueA;
  final double valueB;
  const _ComparisonRow(this.label, this.valueA, this.valueB);
}
