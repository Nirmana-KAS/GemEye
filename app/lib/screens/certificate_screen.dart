import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../config/theme.dart';
import '../models/grade_result.dart';
import '../services/certificate_service.dart';

class CertificateScreen extends StatefulWidget {
  final GradeResult result;
  final Uint8List stoneImageBytes;
  final Uint8List? gradcamImageBytes;

  const CertificateScreen({
    super.key,
    required this.result,
    required this.stoneImageBytes,
    this.gradcamImageBytes,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    try {
      final bytes = await CertificateService.generateCertificatePdf(
        result: widget.result,
        stoneImage: widget.stoneImageBytes,
        gradcamImage: widget.gradcamImageBytes,
      );
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Certificate PDF Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate certificate PDF')),
        );
      }
    }
  }

  Future<void> _savePdf() async {
    if (_pdfBytes == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final certNum = widget.result.certificateNumber ?? 'certificate';
      final file = File('${dir.path}/$certNum.pdf');
      await file.writeAsBytes(_pdfBytes!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Certificate saved to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save certificate')),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    try {
      final certNum = widget.result.certificateNumber ?? 'GemEye-Certificate';
      await Printing.sharePdf(bytes: _pdfBytes!, filename: '$certNum.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share certificate')),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    try {
      await Printing.layoutPdf(onLayout: (_) async => _pdfBytes!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open print dialog')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Certificate'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: GemEyeColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Generating certificate...',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 14,
                      color: GemEyeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _pdfBytes == null
              ? const Center(
                  child: Text(
                    'Failed to generate PDF',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 14,
                      color: GemEyeColors.error,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: PdfPreview(
                        build: (_) async => _pdfBytes!,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                        allowPrinting: false,
                        allowSharing: false,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: GemEyeColors.border)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _actionButton(Icons.save_alt_rounded, 'Save', _savePdf),
                            _actionButton(Icons.share_rounded, 'Share', _sharePdf),
                            _actionButton(Icons.print_rounded, 'Print', _printPdf),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: GemEyeColors.primary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: GemEyeColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
