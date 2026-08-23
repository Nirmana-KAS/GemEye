import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/grade_result.dart';
import '../services/storage_service.dart';
import '../services/certificate_service.dart';
import 'certificate_screen.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final GradeResult? gradeResult;

  const ResultScreen({
    super.key,
    required this.imagePath,
    this.gradeResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  late GradeResult _result;
  bool _isSaving = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _result = widget.gradeResult ?? _createMockResult();
  }

  GradeResult _createMockResult() {
    return GradeResult(
      stoneId: 'GE-STONE-00000',
      gradeNumber: 3,
      gradeName: 'Vivid',
      tradeName: 'Royal Blue',
      confidence: 92.4,
      uncertaintyRange: 0.2,
      labL: 42.3,
      labA: 8.9,
      labB: -27.0,
      labC: 28.4,
      hue: 228,
      saturation: 88,
      brightness: 62,
      deltaE: 1.2,
      capturedImagePath: widget.imagePath,
    );
  }

  Future<void> _saveAndGradeNext() async {
    setState(() => _isSaving = true);
    try {
      if (_result.stoneId == 'GE-STONE-00000') {
        final stoneId = await StorageService.getNextStoneId();
        _result = GradeResult(
          id: _result.id,
          stoneId: stoneId,
          gradeNumber: _result.gradeNumber,
          gradeName: _result.gradeName,
          tradeName: _result.tradeName,
          confidence: _result.confidence,
          uncertaintyRange: _result.uncertaintyRange,
          labL: _result.labL,
          labA: _result.labA,
          labB: _result.labB,
          labC: _result.labC,
          hue: _result.hue,
          saturation: _result.saturation,
          brightness: _result.brightness,
          deltaE: _result.deltaE,
          capturedImagePath: _result.capturedImagePath,
          gradcamImagePath: _result.gradcamImagePath,
          certificateNumber: _result.certificateNumber,
          capturedAt: _result.capturedAt,
          sessionId: _result.sessionId,
        );
      }
      await StorageService.saveGradeResult(_result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stone saved — ${_result.stoneId}')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save result')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _exportCertificate() async {
    setState(() => _isExporting = true);
    try {
      if (_result.stoneId == 'GE-STONE-00000') {
        final stoneId = await StorageService.getNextStoneId();
        _result = GradeResult(
          id: _result.id,
          stoneId: stoneId,
          gradeNumber: _result.gradeNumber,
          gradeName: _result.gradeName,
          tradeName: _result.tradeName,
          confidence: _result.confidence,
          uncertaintyRange: _result.uncertaintyRange,
          labL: _result.labL,
          labA: _result.labA,
          labB: _result.labB,
          labC: _result.labC,
          hue: _result.hue,
          saturation: _result.saturation,
          brightness: _result.brightness,
          deltaE: _result.deltaE,
          capturedImagePath: _result.capturedImagePath,
          gradcamImagePath: _result.gradcamImagePath,
          certificateNumber: _result.certificateNumber,
          capturedAt: _result.capturedAt,
          sessionId: _result.sessionId,
        );
      }

      if (_result.certificateNumber == null) {
        final certNumber = await CertificateService.generateCertificateNumber();
        _result.certificateNumber = certNumber;
      }

      await StorageService.saveGradeResult(_result);

      Uint8List stoneImageBytes;
      try {
        stoneImageBytes = await File(widget.imagePath).readAsBytes();
      } catch (_) {
        stoneImageBytes = Uint8List(0);
      }

      if (mounted) {
        AppRoutes.push(
          context,
          CertificateScreen(
            result: _result,
            stoneImageBytes: stoneImageBytes,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate certificate')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareResult() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/gemeye_result.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'GemEye Grade ${_result.gradeNumber} — ${_result.gradeName} (${_result.tradeName})',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share result')),
        );
      }
    }
  }

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
            onPressed: _shareResult,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(widget.imagePath),
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
                      _buildGradeBadge(),
                      const SizedBox(height: 16),
                      _buildColourValues(),
                      const SizedBox(height: 16),
                      _buildGradCam(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAndGradeNext,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save & Grade Next'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isExporting ? null : _exportCertificate,
                        child: _isExporting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: GemEyeColors.primary),
                              )
                            : const Text('Export Certificate'),
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

  Widget _buildGradeBadge() {
    final confidenceColor = _result.confidenceLevel == 'HIGH'
        ? GemEyeColors.success
        : _result.confidenceLevel == 'MEDIUM'
            ? GemEyeColors.warning
            : GemEyeColors.error;

    return Container(
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
          Text(
            'Grade ${_result.gradeNumber}',
            style: const TextStyle(
              fontFamily: GemEyeFonts.heading,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_result.gradeName} — ${_result.tradeName}',
            style: const TextStyle(
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
            child: Text(
              '± ${_result.uncertaintyRange} grades',
              style: const TextStyle(
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
              color: confidenceColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_result.confidenceLevel} CONFIDENCE',
              style: const TextStyle(
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
    );
  }

  Widget _buildColourValues() {
    return Container(
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
          _buildValueRow('Lightness', _result.labL.toStringAsFixed(1), 'Green-Red', _result.labA.toStringAsFixed(1)),
          const SizedBox(height: 8),
          _buildValueRow('Blue-Yellow', _result.labB.toStringAsFixed(1), 'Chroma', _result.labC.toStringAsFixed(1)),
          const SizedBox(height: 8),
          _buildValueRow('Hue', '${_result.hue.toStringAsFixed(0)}°', 'Saturation', '${_result.saturation.toStringAsFixed(0)}%'),
          const SizedBox(height: 8),
          _buildValueRow('Brightness', '${_result.brightness.toStringAsFixed(0)}%', 'Delta E', _result.deltaE.toStringAsFixed(1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: GemEyeColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hex Value',
                  style: TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 12,
                    color: GemEyeColors.textSecondary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(int.parse(_result.gradeColourHex.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(color: GemEyeColors.border),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _result.gradeColourHex,
                      style: const TextStyle(
                        fontFamily: GemEyeFonts.mono,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GemEyeColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradCam() {
    return Container(
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Heatmap generated after model deployment',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Connect to cloud backend to enable',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 9,
                      color: Colors.white54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
