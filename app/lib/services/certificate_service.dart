import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade_result.dart';

/// GemEye Certificate PDF Generator
///
/// A4 = 595.28pt wide x 841.89pt tall
///
/// VERTICAL BUDGET (every point accounted for):
///   Header bar .............. 52pt
///   Blue accent line ........  3pt
///   Top gap ................. 30pt
///   Stone + Grade row ....... 200pt
///   Gap ..................... 26pt
///   Colour table section .... 78pt
///   Gap ..................... 26pt
///   Details + Heatmap row ... 160pt
///   Gap ..................... 26pt
///   Verify + Standard row ... 150pt
///   Flexible fill ........... ~62pt (pushes footer down)
///   Divider .................  1pt
///   Footer bar .............. 28pt
///   TOTAL ................... 842pt
///
/// Horizontal padding: 36pt each side (print-safe)
/// Content width: 595 - 72 = 523pt
/// Left/Right columns: roughly equal flex

class CertificateService {
  // ── Colours ──
  static const _navy = PdfColor.fromInt(0xFF091A72);
  static const _royal = PdfColor.fromInt(0xFF1B3A8C);
  static const _text = PdfColor.fromInt(0xFF1A1A2E);
  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _bg = PdfColor.fromInt(0xFFF5F7FA);
  static const _green = PdfColor.fromInt(0xFF059669);
  static const _white = PdfColors.white;
  static const _badgeBg = PdfColor.fromInt(0xFF2A3F8F);

  // ── Fonts ──
  static final _hb = pw.Font.helveticaBold();
  static final _h = pw.Font.helvetica();
  static final _ho = pw.Font.helveticaOblique();
  static final _c = pw.Font.courier();
  static final _cb = pw.Font.courierBold();

  // ── Page constants ──
  static const double _pad = 36; // horizontal padding (print-safe)

  /// Generate next sequential certificate number
  static Future<String> generateCertificateNumber() async {
    final prefs = await SharedPreferences.getInstance();
    int counter = prefs.getInt('certificate_counter') ?? 0;
    counter++;
    await prefs.setInt('certificate_counter', counter);
    final now = DateTime.now();
    final ym = '${now.year}${now.month.toString().padLeft(2, '0')}';
    return 'GE-$ym-${counter.toString().padLeft(5, '0')}';
  }

  /// Generate the full A4 certificate PDF
  static Future<Uint8List> generateCertificatePdf({
    required GradeResult result,
    required Uint8List stoneImage,
    Uint8List? gradcamImage,
  }) async {
    final pdf = pw.Document();

    // Load logo
    Uint8List? logoBytes;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoBytes = logoData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Logo load failed: $e');
    }

    final stoneImg = pw.MemoryImage(stoneImage);
    final gradcamImg =
        gradcamImage != null ? pw.MemoryImage(gradcamImage) : null;
    final logoImg = logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    final qrData = jsonEncode({
      'cert': result.certificateNumber,
      'grade': result.gradeNumber,
      'stone': result.stoneId,
      'date': _fmtShort(result.capturedAt),
    });

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ════════════════════════════════════════════
              // SECTION 1: HEADER BAR (52pt)
              // ════════════════════════════════════════════
              pw.Container(
                height: 52,
                color: _navy,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: _pad, vertical: 10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Logo + Name
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (logoImg != null)
                          pw.Container(
                            width: 30,
                            height: 30,
                            decoration: pw.BoxDecoration(
                              color: _white,
                              borderRadius:
                                  pw.BorderRadius.all(pw.Radius.circular(15)),
                            ),
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Image(logoImg),
                          ),
                        if (logoImg != null) pw.SizedBox(width: 10),
                        pw.Text('GemEye',
                            style: pw.TextStyle(
                                font: _hb, fontSize: 22, color: _white)),
                      ],
                    ),
                    // Centre title
                    pw.Text('Colour Grading Certificate',
                        style: pw.TextStyle(
                            font: _hb, fontSize: 14, color: _white)),
                    // Cert number
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('Certificate No',
                            style: pw.TextStyle(
                                font: _h,
                                fontSize: 7,
                                color: PdfColors.grey300)),
                        pw.SizedBox(height: 2),
                        pw.Text(result.certificateNumber ?? 'N/A',
                            style: pw.TextStyle(
                                font: _cb, fontSize: 9, color: _white)),
                      ],
                    ),
                  ],
                ),
              ),

              // ════════════════════════════════════════════
              // SECTION 2: BLUE ACCENT LINE (3pt)
              // ════════════════════════════════════════════
              pw.Container(height: 3, color: _royal),

              // Gap
              pw.SizedBox(height: 30),

              // ════════════════════════════════════════════
              // SECTION 3: STONE IMAGE + GRADE CARD (200pt)
              //   Equal flex: 1 and 1
              // ════════════════════════════════════════════
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: _pad),
                child: pw.SizedBox(
                  height: 200,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // LEFT: Stone image (flex 1)
                      pw.Expanded(
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: _border, width: 1),
                          ),
                          child: pw.Center(
                            child: pw.Image(stoneImg, fit: pw.BoxFit.contain),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      // RIGHT: Grade card (flex 1)
                      pw.Expanded(
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            color: _navy,
                            borderRadius:
                                pw.BorderRadius.all(pw.Radius.circular(10)),
                          ),
                          padding: const pw.EdgeInsets.all(16),
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text('GEMCLOUD Grade',
                                  style: pw.TextStyle(
                                      font: _h,
                                      fontSize: 10,
                                      color: PdfColors.grey300)),
                              pw.SizedBox(height: 8),
                              pw.Text('Grade ${result.gradeNumber}',
                                  style: pw.TextStyle(
                                      font: _hb, fontSize: 42, color: _white)),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                  '${result.gradeName} - ${result.tradeName}',
                                  style: pw.TextStyle(
                                      font: _h, fontSize: 14, color: _white)),
                              pw.SizedBox(height: 14),
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  _badge(
                                      '+/- ${result.uncertaintyRange} grades',
                                      _badgeBg),
                                  pw.SizedBox(width: 8),
                                  _badge(result.confidenceLevel, _green),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Gap
              pw.SizedBox(height: 26),

              // ════════════════════════════════════════════
              // SECTION 4: COLOUR VALUES TABLE (78pt)
              // ════════════════════════════════════════════
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: _pad),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('COLOUR VALUES'),
                    pw.SizedBox(height: 10),
                    pw.Table(
                      border: pw.TableBorder.all(color: _border, width: 0.5),
                      columnWidths: {
                        for (int i = 0; i < 9; i++)
                          i: const pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: _bg),
                          children: [
                            'Lightness',
                            'Green-Red',
                            'Blue-Yel',
                            'Chroma',
                            'Hue',
                            'Sat',
                            'Bright',
                            'Delta E',
                            'Hex',
                          ].map((h) => _tH(h)).toList(),
                        ),
                        pw.TableRow(
                          children: [
                            '${result.labL}',
                            '${result.labA}',
                            '${result.labB}',
                            '${result.labC}',
                            '${result.hue.toStringAsFixed(0)}',
                            '${result.saturation.toStringAsFixed(0)}%',
                            '${result.brightness.toStringAsFixed(0)}%',
                            '${result.deltaE}',
                            result.gradeColourHex,
                          ].map((v) => _tV(v)).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Gap
              pw.SizedBox(height: 26),

              // ════════════════════════════════════════════
              // SECTION 5: STONE DETAILS + AI MAP (160pt)
              //   Equal flex: 1 and 1
              // ════════════════════════════════════════════
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: _pad),
                child: pw.SizedBox(
                  height: 160,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // LEFT: Stone Details (flex 1)
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('STONE DETAILS'),
                            pw.SizedBox(height: 12),
                            _kvRow('Stone ID', result.stoneId),
                            _kvRow('Capture Date', _fmtLong(result.capturedAt)),
                            _kvRow(
                                'Session ID',
                                result.sessionId.length > 22
                                    ? result.sessionId.substring(0, 22)
                                    : result.sessionId),
                            _kvRow('Grade Colour', result.gradeColourHex),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 30),
                      // RIGHT: AI Attention Map (flex 1)
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('AI ATTENTION MAP'),
                            pw.SizedBox(height: 12),
                            pw.Expanded(
                              child: gradcamImg != null
                                  ? pw.Container(
                                      decoration: pw.BoxDecoration(
                                        border: pw.Border.all(
                                            color: _border, width: 0.5),
                                      ),
                                      child: pw.Center(
                                        child: pw.Image(gradcamImg,
                                            fit: pw.BoxFit.contain),
                                      ),
                                    )
                                  : pw.Container(
                                      decoration: pw.BoxDecoration(
                                        color: _bg,
                                        border: pw.Border.all(
                                            color: _border, width: 0.5),
                                        borderRadius: pw.BorderRadius.all(
                                            pw.Radius.circular(4)),
                                      ),
                                      child: pw.Center(
                                        child: pw.Text(
                                            'Heatmap generated\nafter model deployment',
                                            style: pw.TextStyle(
                                                font: _h,
                                                fontSize: 9,
                                                color: _muted),
                                            textAlign: pw.TextAlign.center),
                                      ),
                                    ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text('Grad-CAM visualization',
                                style: pw.TextStyle(
                                    font: _h, fontSize: 7, color: _muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Gap
              pw.SizedBox(height: 26),

              // ════════════════════════════════════════════
              // SECTION 6: VERIFICATION + CLASSIFICATION (150pt)
              //   Equal flex: 1 and 1
              // ════════════════════════════════════════════
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: _pad),
                child: pw.SizedBox(
                  height: 150,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // LEFT: Verification (flex 1)
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('VERIFICATION'),
                            pw.SizedBox(height: 12),
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: qrData,
                                  width: 72,
                                  height: 72,
                                ),
                                pw.SizedBox(width: 12),
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.SizedBox(height: 8),
                                      pw.Text('Scan to verify',
                                          style: pw.TextStyle(
                                              font: _h,
                                              fontSize: 9,
                                              color: _muted)),
                                      pw.Text('certificate data',
                                          style: pw.TextStyle(
                                              font: _h,
                                              fontSize: 9,
                                              color: _muted)),
                                      pw.SizedBox(height: 8),
                                      pw.Text(result.certificateNumber ?? '',
                                          style: pw.TextStyle(
                                              font: _cb,
                                              fontSize: 8,
                                              color: _text)),
                                      pw.SizedBox(height: 8),
                                      pw.Container(
                                        padding: const pw.EdgeInsets.all(6),
                                        decoration: pw.BoxDecoration(
                                          color: _bg,
                                          borderRadius: pw.BorderRadius.all(
                                              pw.Radius.circular(4)),
                                        ),
                                        child: pw.Text(
                                            'Contains: grade, stone ID,\ncapture date, colour data',
                                            style: pw.TextStyle(
                                                font: _h,
                                                fontSize: 7,
                                                color: _muted)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 30),
                      // RIGHT: Classification (flex 1)
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('CLASSIFICATION STANDARD'),
                            pw.SizedBox(height: 12),
                            pw.Text(
                              'Classified according to the GEMCLOUD '
                              '7-Grade Colour Intensity Standard. '
                              'Grading performed using colour-calibrated '
                              'smartphone macro photography and '
                              'cloud-deployed ensemble machine learning '
                              '(EfficientNet-B0 + Random Forest).',
                              style: pw.TextStyle(
                                  font: _h,
                                  fontSize: 8.5,
                                  color: _text,
                                  lineSpacing: 3.5),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              'This document characterises colour but '
                              'does not value the gemstone. It is not '
                              'a substitute for certified gemological '
                              'laboratory reports.',
                              style: pw.TextStyle(
                                  font: _ho,
                                  fontSize: 7.5,
                                  color: _muted,
                                  lineSpacing: 3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ════════════════════════════════════════════
              // FLEXIBLE SPACER — fills remaining ~62pt
              // ════════════════════════════════════════════
              pw.Expanded(child: pw.SizedBox()),

              // ════════════════════════════════════════════
              // SECTION 7: FOOTER (29pt total)
              // ════════════════════════════════════════════
              pw.Container(height: 1, color: _border),
              pw.Container(
                height: 28,
                color: _bg,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: _pad, vertical: 7),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('GemEye v1.0 - 2026',
                        style:
                            pw.TextStyle(font: _h, fontSize: 7, color: _muted)),
                    pw.Text('Certificate No: ${result.certificateNumber}',
                        style:
                            pw.TextStyle(font: _c, fontSize: 7, color: _muted)),
                    pw.Text('Generated: ${_fmtSlash(DateTime.now())}',
                        style:
                            pw.TextStyle(font: _h, fontSize: 7, color: _muted)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ══════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════

  static pw.Widget _badge(String text, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Text(text,
          style: pw.TextStyle(font: _hb, fontSize: 9, color: _white)),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _royal, width: 1.5)),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(font: _hb, fontSize: 11, color: _royal)),
    );
  }

  static pw.Widget _tH(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 7),
      child: pw.Text(text,
          style: pw.TextStyle(font: _hb, fontSize: 7, color: _royal),
          textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _tV(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: pw.Text(text,
          style: pw.TextStyle(font: _c, fontSize: 9, color: _text),
          textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _kvRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(font: _h, fontSize: 9, color: _muted)),
          pw.Text(value,
              style: pw.TextStyle(font: _hb, fontSize: 9, color: _text)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // DATE FORMATTERS
  // ══════════════════════════════════════════════

  static String _fmtLong(DateTime dt) {
    const m = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  static String _fmtShort(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _fmtSlash(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
