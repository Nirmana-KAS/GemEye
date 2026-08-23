import 'dart:typed_data';
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
    final certNumber = result.certificateNumber ?? 'N/A';
    final stoneImg = pw.MemoryImage(stoneImage);
    final gradcamImg = gradcamImage != null ? pw.MemoryImage(gradcamImage) : null;

    final primaryColour = PdfColor.fromHex('#1B3A8C');
    final darkNavy = PdfColor.fromHex('#091A72');
    final borderColour = PdfColor.fromHex('#E5E7F0');
    final textSecondary = PdfColor.fromHex('#6B7089');

    PdfColor confidenceColour;
    switch (result.confidenceLevel) {
      case 'HIGH':
        confidenceColour = PdfColor.fromHex('#10B981');
        break;
      case 'MEDIUM':
        confidenceColour = PdfColor.fromHex('#F59E0B');
        break;
      default:
        confidenceColour = PdfColor.fromHex('#EF4444');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'GemEye',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColour,
                    ),
                  ),
                  pw.Text(
                    'Colour Grading Certificate',
                    style: const pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    certNumber,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColour,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: primaryColour, thickness: 2),
              pw.SizedBox(height: 20),

              // Stone image
              pw.Center(
                child: pw.Container(
                  width: 170,
                  height: 170,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColour, width: 1),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(stoneImg, fit: pw.BoxFit.cover),
                  ),
                ),
              ),
              pw.SizedBox(height: 16),

              // Grade result card
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: pw.BoxDecoration(
                  color: darkNavy,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'GEMCLOUD Grade',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Grade ${result.gradeNumber}',
                      style: const pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${result.gradeName} — ${result.tradeName}',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white.shade(0.85),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        '± ${result.uncertaintyRange} grades',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: confidenceColour,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        result.confidenceLevel,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Colour data table
              pw.Table(
                border: pw.TableBorder.all(color: borderColour, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: ['L*', 'a*', 'b*', 'C*', 'Hue', 'Sat', 'Brt', 'ΔE₀₀']
                        .map((h) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(h,
                                  textAlign: pw.TextAlign.center,
                                  style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ))
                        .toList(),
                  ),
                  pw.TableRow(
                    children: [
                      result.labL.toStringAsFixed(1),
                      result.labA.toStringAsFixed(1),
                      result.labB.toStringAsFixed(1),
                      result.labC.toStringAsFixed(1),
                      '${result.hue.toStringAsFixed(0)}°',
                      '${result.saturation.toStringAsFixed(0)}%',
                      '${result.brightness.toStringAsFixed(0)}%',
                      result.deltaE.toStringAsFixed(1),
                    ]
                        .map((v) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(v, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
                            ))
                        .toList(),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Grad-CAM
              if (gradcamImg != null) ...[
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 110,
                      height: 110,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColour),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Image(gradcamImg, fit: pw.BoxFit.cover),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Text(
                      'AI Attention Regions',
                      style: pw.TextStyle(fontSize: 10, color: textSecondary, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
              ],

              // Stone details
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColour),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _pdfDetailCol('Stone ID', result.stoneId),
                    _pdfDetailCol('Capture Date', _formatDate(result.capturedAt)),
                    _pdfDetailCol('Session ID', result.sessionId),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Standard line
              pw.Center(
                child: pw.Text(
                  'Classified according to the GEMCLOUD 7-Grade Colour Intensity Standard',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColour),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 6),

              // Disclaimer
              pw.Center(
                child: pw.Text(
                  'This certificate is generated by the GemEye automated colour grading system. '
                  'It is not a substitute for certified gemological laboratory reports.',
                  style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: textSecondary),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: borderColour, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GemEye v1.0 · 2026', style: pw.TextStyle(fontSize: 8, color: textSecondary)),
                  pw.Text(certNumber, style: pw.TextStyle(fontSize: 8, color: textSecondary)),
                  pw.Text('Generated: ${_formatDate(DateTime.now())}', style: pw.TextStyle(fontSize: 8, color: textSecondary)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfDetailCol(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#6B7089'))),
        pw.SizedBox(height: 2),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
