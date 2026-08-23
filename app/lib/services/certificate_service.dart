import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade_result.dart';
import '../config/constants.dart';

class CertificateService {
  static const String _counterKey = 'certificate_counter';

  static Future<String> generateCertificateNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final counter = (prefs.getInt(_counterKey) ?? 0) + 1;
    await prefs.setInt(_counterKey, counter);
    final now = DateTime.now();
    final yearMonth = '${now.year}${now.month.toString().padLeft(2, '0')}';
    return '${AppConstants.defaultCertificatePrefix}-$yearMonth-${counter.toString().padLeft(5, '0')}';
  }

  static Future<Uint8List> generateCertificatePdf({
    required GradeResult result,
    required Uint8List stoneImage,
    Uint8List? gradcamImage,
  }) async {
    final pdf = pw.Document();

    Uint8List? logoBytes;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoBytes = logoData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Logo not found: $e');
    }

    final stoneImg = pw.MemoryImage(stoneImage);
    final gradcamImg =
        gradcamImage != null ? pw.MemoryImage(gradcamImage) : null;
    final logoImg = logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(result, logoImg),
              pw.Container(
                  width: double.infinity,
                  height: 3,
                  color: PdfColor.fromHex('#1B3A8C')),
              _buildGradeSection(result, stoneImg),
              _buildColourTable(result),
              _buildDetailsSection(result, gradcamImg),
              _buildVerificationSection(result),
              pw.SizedBox(height: 20),
              _buildFooter(result),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
      GradeResult result, pw.MemoryImage? logoImg) {
    return pw.Container(
      width: double.infinity,
      color: PdfColor.fromHex('#091A72'),
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(children: [
            if (logoImg != null) pw.Image(logoImg, width: 24, height: 24),
            if (logoImg != null) pw.SizedBox(width: 8),
            pw.Text('GemEye',
                style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  fontSize: 20,
                  color: PdfColors.white,
                )),
          ]),
          pw.Text('Colour Grading Certificate',
              style: pw.TextStyle(
                font: pw.Font.helveticaBold(),
                fontSize: 14,
                color: PdfColors.white,
              )),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Certificate No',
                  style: pw.TextStyle(
                    font: pw.Font.helvetica(),
                    fontSize: 7,
                    color: PdfColors.grey300,
                  )),
              pw.Text(result.certificateNumber ?? 'N/A',
                  style: pw.TextStyle(
                    font: pw.Font.courierBold(),
                    fontSize: 10,
                    color: PdfColors.white,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGradeSection(
      GradeResult result, pw.MemoryImage stoneImg) {
    PdfColor confidenceColor;
    switch (result.confidenceLevel) {
      case 'HIGH':
        confidenceColor = PdfColor.fromHex('#059669');
        break;
      case 'MEDIUM':
        confidenceColor = PdfColor.fromHex('#F59E0B');
        break;
      default:
        confidenceColor = PdfColor.fromHex('#EF4444');
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 160,
            height: 160,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                  color: PdfColor.fromHex('#E5E7EB'), width: 1),
            ),
            child: pw.Center(
                child: pw.Image(stoneImg,
                    fit: pw.BoxFit.contain, width: 155, height: 155)),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#091A72'),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('GEMCLOUD Grade',
                      style: pw.TextStyle(
                        font: pw.Font.helvetica(),
                        fontSize: 9,
                        color: PdfColors.grey300,
                      )),
                  pw.SizedBox(height: 4),
                  pw.Text('Grade ${result.gradeNumber}',
                      style: pw.TextStyle(
                        font: pw.Font.helveticaBold(),
                        fontSize: 36,
                        color: PdfColors.white,
                      )),
                  pw.SizedBox(height: 2),
                  pw.Text('${result.gradeName} - ${result.tradeName}',
                      style: pw.TextStyle(
                        font: pw.Font.helvetica(),
                        fontSize: 13,
                        color: PdfColors.white,
                      )),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#2A3F8F'),
                          borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(10)),
                        ),
                        child: pw.Text(
                            '+/- ${result.uncertaintyRange} grades',
                            style: pw.TextStyle(
                              font: pw.Font.helvetica(),
                              fontSize: 8,
                              color: PdfColors.white,
                            )),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: confidenceColor,
                          borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(10)),
                        ),
                        child: pw.Text(result.confidenceLevel,
                            style: pw.TextStyle(
                              font: pw.Font.helveticaBold(),
                              fontSize: 8,
                              color: PdfColors.white,
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildColourTable(GradeResult result) {
    final headers = [
      'Lightness',
      'Green-Red',
      'Blue-Yel',
      'Chroma',
      'Hue',
      'Sat',
      'Bright',
      'Delta E',
      'Hex',
    ];
    final values = [
      result.labL.toStringAsFixed(1),
      result.labA.toStringAsFixed(1),
      result.labB.toStringAsFixed(1),
      result.labC.toStringAsFixed(1),
      result.hue.toStringAsFixed(0),
      '${result.saturation.toStringAsFixed(0)}%',
      '${result.brightness.toStringAsFixed(0)}%',
      result.deltaE.toStringAsFixed(1),
      result.gradeColourHex,
    ];

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(
                      color: PdfColor.fromHex('#1B3A8C'), width: 1.5)),
            ),
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text('COLOUR VALUES',
                style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  fontSize: 11,
                  color: PdfColor.fromHex('#1B3A8C'),
                )),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColor.fromHex('#E5E7EB'), width: 0.5),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F5F7FA')),
                children: headers
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 3, vertical: 6),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                font: pw.Font.helveticaBold(),
                                fontSize: 7,
                                color: PdfColor.fromHex('#1B3A8C'),
                              ),
                              textAlign: pw.TextAlign.center),
                        ))
                    .toList(),
              ),
              pw.TableRow(
                children: values
                    .map((v) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 3, vertical: 6),
                          child: pw.Text(v,
                              style: pw.TextStyle(
                                font: pw.Font.courier(),
                                fontSize: 9,
                                color: PdfColor.fromHex('#1A1A2E'),
                              ),
                              textAlign: pw.TextAlign.center),
                        ))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailsSection(
      GradeResult result, pw.MemoryImage? gradcamImg) {
    return pw.Padding(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionHeader('STONE DETAILS'),
                pw.SizedBox(height: 8),
                _detailRow('Stone ID', result.stoneId),
                _detailRow('Capture Date', _formatDate(result.capturedAt)),
                _detailRow(
                    'Session ID',
                    result.sessionId.length > 18
                        ? result.sessionId.substring(0, 18)
                        : result.sessionId),
              ],
            ),
          ),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionHeader('AI ATTENTION MAP'),
                pw.SizedBox(height: 8),
                if (gradcamImg != null)
                  pw.Container(
                    width: 140,
                    height: 100,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                          color: PdfColor.fromHex('#E5E7EB'),
                          width: 0.5),
                    ),
                    child: pw.Image(gradcamImg,
                        fit: pw.BoxFit.contain),
                  )
                else
                  pw.Container(
                    width: 140,
                    height: 100,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F5F7FA'),
                      border: pw.Border.all(
                          color: PdfColor.fromHex('#E5E7EB'),
                          width: 0.5),
                      borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4)),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                          'Heatmap generated\nafter model deployment',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 8,
                            color: PdfColor.fromHex('#6B7280'),
                          ),
                          textAlign: pw.TextAlign.center),
                    ),
                  ),
                pw.SizedBox(height: 4),
                pw.Text('Grad-CAM visualization',
                    style: pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: 7,
                      color: PdfColor.fromHex('#6B7280'),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildVerificationSection(GradeResult result) {
    final qrData = jsonEncode({
      'cert': result.certificateNumber ?? '',
      'grade': result.gradeNumber,
      'stone': result.stoneId,
      'date': _formatDateShort(result.capturedAt),
    });

    return pw.Padding(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 180,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionHeader('VERIFICATION'),
                pw.SizedBox(height: 8),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: qrData,
                      width: 56,
                      height: 56,
                    ),
                    pw.SizedBox(width: 8),
                    pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Scan to verify',
                            style: pw.TextStyle(
                              font: pw.Font.helvetica(),
                              fontSize: 8,
                              color: PdfColor.fromHex('#6B7280'),
                            )),
                        pw.Text('certificate data',
                            style: pw.TextStyle(
                              font: pw.Font.helvetica(),
                              fontSize: 8,
                              color: PdfColor.fromHex('#6B7280'),
                            )),
                        pw.SizedBox(height: 4),
                        pw.Text(result.certificateNumber ?? '',
                            style: pw.TextStyle(
                              font: pw.Font.courierBold(),
                              fontSize: 8,
                              color: PdfColor.fromHex('#1A1A2E'),
                            )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionHeader('CLASSIFICATION STANDARD'),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Classified according to the GEMCLOUD 7-Grade Colour Intensity Standard. Grading performed using colour-calibrated smartphone macro photography and cloud-deployed ensemble machine learning (EfficientNet-B0 + Random Forest).',
                  style: pw.TextStyle(
                    font: pw.Font.helvetica(),
                    fontSize: 8,
                    color: PdfColor.fromHex('#1A1A2E'),
                    lineSpacing: 3,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'This document characterises colour but does not value the gemstone. It is not a substitute for certified gemological laboratory reports.',
                  style: pw.TextStyle(
                    font: pw.Font.helveticaOblique(),
                    fontSize: 7,
                    color: PdfColor.fromHex('#6B7280'),
                    lineSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(GradeResult result) {
    final now = DateTime.now();
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(
                color: PdfColor.fromHex('#E5E7EB'), width: 1)),
      ),
      color: PdfColor.fromHex('#F5F7FA'),
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('GemEye v1.0 - 2026',
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 7,
                color: PdfColor.fromHex('#6B7280'),
              )),
          pw.Text(
              'Certificate No: ${result.certificateNumber ?? 'N/A'}',
              style: pw.TextStyle(
                font: pw.Font.courier(),
                fontSize: 7,
                color: PdfColor.fromHex('#6B7280'),
              )),
          pw.Text('Generated: ${_formatDateSlash(now)}',
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 7,
                color: PdfColor.fromHex('#6B7280'),
              )),
        ],
      ),
    );
  }

  static pw.Widget _sectionHeader(String title) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(
                color: PdfColor.fromHex('#1B3A8C'), width: 1.5)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(title,
          style: pw.TextStyle(
            font: pw.Font.helveticaBold(),
            fontSize: 11,
            color: PdfColor.fromHex('#1B3A8C'),
          )),
    );
  }

  static pw.Widget _detailRow(String label, String value) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(
                color: PdfColor.fromHex('#E5E7EB'), width: 0.5)),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 9,
                color: PdfColor.fromHex('#6B7280'),
              )),
          pw.Text(value,
              style: pw.TextStyle(
                font: pw.Font.helveticaBold(),
                fontSize: 9,
                color: PdfColor.fromHex('#1A1A2E'),
              )),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String _formatDateShort(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static String _formatDateSlash(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
