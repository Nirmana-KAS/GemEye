import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/grade_result.dart';
import '../utils/colour_math.dart';
import '../widgets/confidence_badge.dart';
import 'calibration_service.dart';
import 'profile_service.dart';
import 'settings_service.dart';

/// GemEye Certificate PDF generator (Group E design).
///
/// A4 = 595.28 x 841.89 pt. The design is drawn at 794 x 1123 px, so every
/// design measurement is multiplied by 0.75 to get points.
class CertificateService {
  // Colours (from the app theme)
  static PdfColor _pdf(Color c) => PdfColor.fromInt(c.toARGB32());
  static final _primary = _pdf(AppColors.primary);
  static final _text = _pdf(AppColors.textPrimary);
  static final _secondary = _pdf(AppColors.textSecondary);
  static final _border = _pdf(AppColors.border);
  static final _white = _pdf(AppColors.background);
  static final _warning = _pdf(AppColors.warning);
  static final _success = _pdf(AppColors.success);
  static final _error = _pdf(AppColors.error);
  static final _gradeLight = _pdf(AppColors.grade7);
  static final _gradientStart = _pdf(AppColors.grade3);

  /// [base] with [alpha] of [over] painted on top (PDF fills are opaque).
  static PdfColor _mix(PdfColor base, PdfColor over, double alpha) =>
      PdfColor(
        base.red + (over.red - base.red) * alpha,
        base.green + (over.green - base.green) * alpha,
        base.blue + (over.blue - base.blue) * alpha,
      );

  // Page constants
  static const double _pad = 30;

  /// Generate next sequential certificate number, using the prefix set in
  /// Settings (default GE).
  static Future<String> generateCertificateNumber() async {
    final prefs = await SharedPreferences.getInstance();
    int counter = prefs.getInt('certificate_counter') ?? 0;
    counter++;
    await prefs.setInt('certificate_counter', counter);
    final now = DateTime.now();
    final ym = '${now.year}${now.month.toString().padLeft(2, '0')}';
    final prefix = SettingsService.certificatePrefix.value.trim().isEmpty
        ? AppConstants.defaultCertificatePrefix
        : SettingsService.certificatePrefix.value.trim();
    return '$prefix-$ym-${counter.toString().padLeft(5, '0')}';
  }

  static Future<pw.Font?> _font(String asset) async {
    try {
      return pw.Font.ttf(await rootBundle.load(asset));
    } catch (e) {
      debugPrint('Certificate font load failed ($asset): $e');
      return null;
    }
  }

  /// Generate the full A4 certificate PDF.
  ///
  /// [gradcamImage] is accepted for compatibility; the Group E certificate
  /// layout has no Grad-CAM panel (it stays on the Grade Result screen).
  static Future<Uint8List> generateCertificatePdf({
    required GradeResult result,
    required Uint8List stoneImage,
    Uint8List? gradcamImage,
  }) async {
    final pdf = pw.Document();

    final poppinsSemi = await _font('assets/fonts/Poppins-SemiBold.ttf') ??
        pw.Font.helveticaBold();
    final poppinsBold =
        await _font('assets/fonts/Poppins-Bold.ttf') ?? pw.Font.helveticaBold();
    final inter =
        await _font('assets/fonts/Inter-Regular.ttf') ?? pw.Font.helvetica();
    final interMed =
        await _font('assets/fonts/Inter-Medium.ttf') ?? pw.Font.helvetica();
    final mono = await _font('assets/fonts/JetBrainsMono-Regular.ttf') ??
        pw.Font.courier();

    Uint8List? logoBytes;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoBytes = logoData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Logo load failed: $e');
    }

    final stoneImg = pw.MemoryImage(stoneImage);
    final logoImg = logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    // QR content unchanged.
    // TODO(backend): encode a verification URL once the verify endpoint exists.
    final qrData = jsonEncode({
      'cert': result.certificateNumber,
      'grade': result.gradeNumber,
      'stone': result.stoneId,
      'date': _fmtShort(result.capturedAt),
    });

    // Calibration session details, when the result's session is known.
    CalibrationSession? calibration;
    try {
      for (final s in await CalibrationService.history()) {
        if (s.id == result.sessionId) {
          calibration = s;
          break;
        }
      }
    } catch (e) {
      debugPrint('Certificate calibration lookup failed: $e');
    }

    String issuedTo = '-';
    try {
      final name = FirebaseAuth.instance.currentUser?.displayName?.trim();
      if (name != null && name.isNotEmpty) issuedTo = name;
    } catch (e) {
      debugPrint('Certificate user lookup failed: $e');
    }

    String? company;
    try {
      final c = (await ProfileService.load()).companyName.trim();
      if (c.isNotEmpty) company = c;
    } catch (e) {
      debugPrint('Certificate company lookup failed: $e');
    }

    final referred = result.confidence < ConfidenceBadge.referThreshold;
    final gradeColour = AppColors.grades[(result.gradeNumber - 1).clamp(0, 6)];
    final rgb = result.measuredRgb;
    final measured = PdfColor.fromInt(
        0xFF000000 | rgb[0] << 16 | rgb[1] << 8 | rgb[2]);
    final gradientMid = _mix(_gradientStart, _primary, 0.5);
    final pillBg = _mix(gradientMid, _white, 0.14);
    final pillBorder = _mix(gradientMid, _white, 0.2);

    final (String confLevel, PdfColor confDot) =
        result.confidence >= ConfidenceBadge.referThreshold
            ? ('High', _success)
            : result.confidence >= ConfidenceBadge.lowThreshold
                ? ('Borderline', _warning)
                : ('Low', _error);

    pw.TextStyle st(pw.Font f, double size, PdfColor c,
            {double spacing = 0, double? height}) =>
        pw.TextStyle(
          font: f,
          fontSize: size,
          color: c,
          letterSpacing: spacing,
          lineSpacing: height == null ? 0 : size * (height - 1),
        );

    // TODO(backend): CIECAM02 values are not in GradeResult yet.
    final groups = <String, List<List<String>>>{
      'CIELAB': [
        ['Lightness (L*)', result.labL.toStringAsFixed(1)],
        ['Green-Red (a*)', result.labA.toStringAsFixed(1)],
        ['Blue-Yellow (b*)', result.labB.toStringAsFixed(1)],
        ['Chroma (C*)', result.labC.toStringAsFixed(1)],
      ],
      'HSB': [
        ['Hue', '${result.hue.toStringAsFixed(0)}°'],
        ['Saturation', '${result.saturation.toStringAsFixed(0)}%'],
        ['Brightness', '${result.brightness.toStringAsFixed(0)}%'],
      ],
      'CIECAM02': [
        ['Lightness J', '-'],
        ['Colourfulness M', '-'],
        ['Hue angle h', '-'],
        ['Saturation s', '-'],
        ['Chroma C', '-'],
      ],
    };

    // TODO(backend): model version from the grading response.
    const modelVersion = '-';
    final details = <(String, String, bool)>[
      ('Stone ID', result.stoneId, true),
      ('Capture date / time', _fmtDateTime(result.capturedAt), false),
      ('Session', result.sessionId, true),
      ('Device', calibration?.deviceModel ?? '-', false),
      (
        'Calibration residual',
        calibration == null
            ? '-'
            : '${calibration.residual.toStringAsFixed(2)} · '
                '${calibration.quality.label}',
        false,
      ),
      ('Model version', modelVersion, false),
      ('Issued to', issuedTo, false),
      if (company != null) ('Company', company, false),
    ];

    pw.Widget pill(List<pw.Widget> children, {bool outlined = false}) =>
        pw.Container(
          height: 19.5,
          padding: const pw.EdgeInsets.symmetric(horizontal: 9),
          decoration: pw.BoxDecoration(
            color: pillBg,
            borderRadius: pw.BorderRadius.circular(9.75),
            border:
                outlined ? pw.Border.all(color: pillBorder, width: 0.75) : null,
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: children,
          ),
        );

    pw.Widget card(pw.Widget child, {pw.EdgeInsets? padding}) => pw.Container(
          padding: padding ??
              const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.75),
            borderRadius: pw.BorderRadius.circular(9),
          ),
          child: child,
        );

    pw.Widget detailCell((String, String, bool) d) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(d.$1, style: st(inter, 8.25, _secondary)),
            pw.SizedBox(height: 3),
            pw.Text(d.$2,
                maxLines: 1, style: st(d.$3 ? mono : interMed, 9, _text)),
          ],
        );

    final detailRows = <pw.Widget>[];
    for (var i = 0; i < details.length; i += 2) {
      if (i > 0) detailRows.add(pw.SizedBox(height: 9));
      detailRows.add(pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: detailCell(details[i])),
          pw.SizedBox(width: 18),
          pw.Expanded(
            child: i + 1 < details.length
                ? detailCell(details[i + 1])
                : pw.SizedBox(),
          ),
        ],
      ));
    }

    pw.Widget hPad(pw.Widget child) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: _pad),
          child: child,
        );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Container(
                height: 72,
                color: _primary,
                padding: const pw.EdgeInsets.symmetric(horizontal: _pad),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 33,
                      height: 33,
                      padding: const pw.EdgeInsets.all(3),
                      decoration: pw.BoxDecoration(
                        color: _white,
                        borderRadius: pw.BorderRadius.circular(9),
                      ),
                      child:
                          logoImg != null ? pw.Image(logoImg) : pw.SizedBox(),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('GemEye',
                              style:
                                  st(poppinsBold, 9.75, _white, spacing: 0.4)),
                          pw.SizedBox(height: 3),
                          pw.Text('Colour Grading Certificate',
                              style: st(poppinsSemi, 16.5, _white)),
                        ],
                      ),
                    ),
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('CERTIFICATE NO.',
                            style:
                                st(poppinsSemi, 7.5, _gradeLight, spacing: 1)),
                        pw.SizedBox(height: 3),
                        pw.Text(result.certificateNumber ?? '-',
                            style: st(mono, 12, _white)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 21),

              // Stone photo + grade block
              hPad(pw.SizedBox(
                height: 174,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Container(
                      width: 174,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _border, width: 0.75),
                        borderRadius: pw.BorderRadius.circular(9),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Expanded(
                            child: pw.ClipRRect(
                              horizontalRadius: 9,
                              verticalRadius: 9,
                              child: pw.SizedBox(
                                width: double.infinity,
                                child:
                                    pw.Image(stoneImg, fit: pw.BoxFit.cover),
                              ),
                            ),
                          ),
                          pw.Container(
                            height: 24,
                            alignment: pw.Alignment.center,
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  top: pw.BorderSide(
                                      color: _border, width: 0.75)),
                            ),
                            child: pw.Text('${result.stoneId} · face-up',
                                style: st(mono, 7.5, _secondary)),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 15),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(18),
                        decoration: pw.BoxDecoration(
                          borderRadius: pw.BorderRadius.circular(10.5),
                          gradient: pw.LinearGradient(
                            begin: pw.Alignment.topLeft,
                            end: pw.Alignment.bottomRight,
                            colors: [_gradientStart, _primary],
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('GEMCLOUD GRADE',
                                        style: st(
                                            poppinsSemi, 8.25, _gradeLight,
                                            spacing: 1.2)),
                                    pw.SizedBox(height: 6),
                                    pw.Text('Grade ${result.gradeNumber}',
                                        style: st(poppinsBold, 36, _white)),
                                    pw.SizedBox(height: 6),
                                    pw.Text(result.gradeName,
                                        style: st(interMed, 12, _white)),
                                    pw.SizedBox(height: 4),
                                    pw.Text('Trade name: ${result.tradeName}',
                                        style: st(inter, 10.5, _white)),
                                  ],
                                ),
                                pw.Column(
                                  children: [
                                    pw.Container(
                                      width: 45,
                                      height: 45,
                                      padding: const pw.EdgeInsets.all(1.5),
                                      decoration: pw.BoxDecoration(
                                        color: _mix(gradientMid, _white, 0.85),
                                        borderRadius:
                                            pw.BorderRadius.circular(10.5),
                                      ),
                                      child: pw.Container(
                                        decoration: pw.BoxDecoration(
                                          color: _pdf(gradeColour),
                                          borderRadius:
                                              pw.BorderRadius.circular(9),
                                        ),
                                      ),
                                    ),
                                    pw.SizedBox(height: 6),
                                    pw.Text(
                                        'G${result.gradeNumber} ${_hex(gradeColour)}',
                                        style: st(mono, 7.5, _white)),
                                  ],
                                ),
                              ],
                            ),
                            pw.Row(
                              children: [
                                pill([
                                  pw.Container(
                                    width: 4.5,
                                    height: 4.5,
                                    decoration: pw.BoxDecoration(
                                      color: confDot,
                                      shape: pw.BoxShape.circle,
                                    ),
                                  ),
                                  pw.SizedBox(width: 6),
                                  pw.Text(
                                      '$confLevel · ${result.confidence.round()}%',
                                      style: st(poppinsSemi, 9, _white)),
                                ]),
                                pw.SizedBox(width: 6),
                                pill([
                                  pw.Text('± ${result.uncertaintyRange} grade',
                                      style: st(poppinsSemi, 9, _white)),
                                ], outlined: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),

              // Borderline gemologist sign-off
              if (referred) ...[
                pw.SizedBox(height: 15),
                hPad(pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: pw.BoxDecoration(
                    color: _mix(_white, _warning, 0.08),
                    border: pw.Border.all(color: _warning, width: 0.75),
                    borderRadius: pw.BorderRadius.circular(9),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 6,
                        height: 6,
                        margin: const pw.EdgeInsets.only(bottom: 3),
                        decoration: pw.BoxDecoration(
                          color: _warning,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 9),
                      pw.Text('Borderline - reviewed by gemologist:',
                          style: st(interMed, 9.75, _text)),
                      pw.SizedBox(width: 9),
                      pw.Expanded(
                        child: pw.Container(
                          height: 12,
                          decoration: pw.BoxDecoration(
                            border: pw.Border(
                                bottom:
                                    pw.BorderSide(color: _text, width: 0.75)),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],

              pw.SizedBox(height: 15),

              // Colour data
              hPad(card(pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Colour data', style: st(poppinsSemi, 10.5, _text)),
                  pw.SizedBox(height: 9),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final (i, g) in groups.entries.indexed) ...[
                        if (i > 0) pw.SizedBox(width: 15),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.only(bottom: 6),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(
                                      bottom: pw.BorderSide(
                                          color: _primary, width: 0.75)),
                                ),
                                child: pw.Text(g.key,
                                    style: st(poppinsSemi, 7.5, _secondary,
                                        spacing: 0.75)),
                              ),
                              for (final r in g.value)
                                pw.Container(
                                  height: 19.5,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(
                                        bottom: pw.BorderSide(
                                            color: _border, width: 0.75)),
                                  ),
                                  child: pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(r[0],
                                          style: st(inter, 9, _secondary)),
                                      pw.Text(r[1], style: st(mono, 9, _text)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Text(
                          '${ColourMath.deltaELabel} to typical Grade ${result.gradeNumber}',
                          style: st(inter, 9, _secondary)),
                      pw.SizedBox(width: 6),
                      // TODO(backend): server ΔE₀₀ to the grade's typical colour.
                      pw.Text(result.deltaE.toStringAsFixed(1),
                          style: st(mono, 9, _text)),
                      pw.SizedBox(width: 18),
                      pw.Text('Hex', style: st(inter, 9, _secondary)),
                      pw.SizedBox(width: 6),
                      pw.Container(
                        width: 12,
                        height: 12,
                        decoration: pw.BoxDecoration(
                          color: measured,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(result.measuredHex, style: st(mono, 9, _text)),
                    ],
                  ),
                ],
              ))),

              pw.SizedBox(height: 15),

              // Details + QR
              hPad(pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: card(pw.Column(children: detailRows))),
                  pw.SizedBox(width: 15),
                  pw.SizedBox(
                    width: 165,
                    child: card(
                      pw.Column(
                        children: [
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: qrData,
                            width: 84,
                            height: 84,
                            color: _text,
                          ),
                          pw.SizedBox(height: 9),
                          pw.Text('Scan to view certificate data',
                              textAlign: pw.TextAlign.center,
                              style: st(poppinsSemi, 9, _text)),
                          pw.SizedBox(height: 3),
                          pw.Text(result.certificateNumber ?? '-',
                              style: st(mono, 7.5, _secondary)),
                        ],
                      ),
                      padding: const pw.EdgeInsets.all(12),
                    ),
                  ),
                ],
              )),

              pw.SizedBox(height: 15),

              // Statement + disclaimer
              hPad(pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                      'Classified according to the GEMCLOUD 7-Grade Colour '
                      'Intensity Standard',
                      style: st(poppinsSemi, 9.75, _primary, height: 1.5)),
                  pw.SizedBox(height: 6),
                  pw.Text(
                      'Generated by the GemEye automated colour grading '
                      'system. Not a substitute for a certified gemological '
                      'laboratory report.',
                      style: st(inter, 8.25, _secondary, height: 1.5)),
                ],
              )),

              pw.Expanded(child: pw.SizedBox()),

              // Footer
              pw.Container(
                height: 33,
                margin: const pw.EdgeInsets.symmetric(horizontal: _pad),
                decoration: pw.BoxDecoration(
                  border:
                      pw.Border(top: pw.BorderSide(color: _border, width: 0.75)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        '${AppConstants.appName} v${AppConstants.appVersion} '
                        '· Model $modelVersion',
                        style: st(mono, 7.5, _secondary)),
                    pw.Text(result.certificateNumber ?? '-',
                        style: st(mono, 7.5, _secondary)),
                    pw.Text('Issued ${_fmtDate(DateTime.now())}',
                        style: st(mono, 7.5, _secondary)),
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

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  // Date formatters

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _fmtDate(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

  static String _fmtDateTime(DateTime dt) =>
      '${_fmtDate(dt)}, ${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  static String _fmtShort(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
