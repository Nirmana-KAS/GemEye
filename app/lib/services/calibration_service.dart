import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image/image.dart' as img;
import '../models/app_notification.dart';
import 'notification_service.dart';

/// Max per-channel standard deviation (0-255) inside the measured region
/// before a patch photo is rejected as not uniform.
// TODO: tune kPatchMaxStd on real captures.
const double kPatchMaxStd = 0.06 * 255;

// Residual thresholds (normalised RGB units).
// Provisional - training session residual was 0.2548.
const double kResidualExcellent = 0.30;
const double kResidualAcceptable = 0.45;

/// How long a calibration session stays valid.
const Duration kCalibrationValidity = Duration(hours: 8);

/// Max sessions kept in the calibration history.
const int kCalibrationHistoryMax = 50;

/// One patch of the GemEye calibration card.
class CalibrationPatch {
  final String name;
  final List<int> rgb;

  const CalibrationPatch(this.name, this.rgb);
}

/// Reference patches, in capture order. MUST match the training code.
const List<CalibrationPatch> kCalibrationPatches = [
  CalibrationPatch('White', [255, 255, 255]),
  CalibrationPatch('Black', [0, 0, 0]),
  CalibrationPatch('18% Grey', [117, 117, 117]),
  CalibrationPatch('50% Grey', [186, 186, 186]),
  CalibrationPatch('Blue', [0, 63, 135]),
  CalibrationPatch('Red', [175, 54, 60]),
];

enum CalibrationQuality { excellent, acceptable, poor }

extension CalibrationQualityLabel on CalibrationQuality {
  String get label => switch (this) {
        CalibrationQuality.excellent => 'Excellent',
        CalibrationQuality.acceptable => 'Acceptable',
        CalibrationQuality.poor => 'Poor',
      };
}

CalibrationQuality qualityForResidual(double residual) {
  if (residual <= kResidualExcellent) return CalibrationQuality.excellent;
  if (residual <= kResidualAcceptable) return CalibrationQuality.acceptable;
  return CalibrationQuality.poor;
}

/// Mean and per-channel standard deviation (0-255) of a patch photo's
/// central 50% region.
class PatchMeasurement {
  final List<double> mean;
  final List<double> std;

  const PatchMeasurement({required this.mean, required this.std});

  bool get isUniform => std.every((s) => s <= kPatchMaxStd);

  List<int> get meanRgb => mean.map((v) => v.round().clamp(0, 255)).toList();
}

/// Result of [CalibrationService.computeCcm].
class CcmResult {
  /// Row-major 3x3 matrix M, applied as corrected = rgb · M (0-1 units).
  final List<double> ccm;
  final double residual;
  final List<double> perPatchError;

  const CcmResult({
    required this.ccm,
    required this.residual,
    required this.perPatchError,
  });

  CalibrationQuality get quality => qualityForResidual(residual);
}

/// A saved calibration session.
class CalibrationSession {
  final String id;
  final DateTime createdAt;
  final DateTime validUntil;
  final String deviceModel;
  final List<double> ccm;
  final double residual;
  final CalibrationQuality quality;

  /// Measured mean RGB (0-255) of the 6 patches, in capture order.
  final List<List<double>> measured;
  final List<double> perPatchError;

  const CalibrationSession({
    required this.id,
    required this.createdAt,
    required this.validUntil,
    required this.deviceModel,
    required this.ccm,
    required this.residual,
    required this.quality,
    required this.measured,
    required this.perPatchError,
  });

  bool get isValid => DateTime.now().isBefore(validUntil);

  /// Session number within its day (the NN of S-YYYY-MM-DD-NN).
  int get dayNumber => int.tryParse(id.split('-').last) ?? 1;

  /// Measured patch [index] after colour correction (0-255).
  List<int> corrected(int index) {
    final m = measured[index];
    return CalibrationService.applyCcm(ccm, m[0], m[1], m[2]);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'validUntil': validUntil.toIso8601String(),
        'deviceModel': deviceModel,
        'ccm': ccm,
        'residual': residual,
        'quality': quality.name,
        'measured': measured,
        'perPatchError': perPatchError,
      };

  factory CalibrationSession.fromJson(Map<String, dynamic> json) {
    List<double> doubles(dynamic v) =>
        (v as List).map((e) => (e as num).toDouble()).toList();
    return CalibrationSession(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      validUntil: DateTime.parse(json['validUntil'] as String),
      deviceModel: json['deviceModel'] as String? ?? 'Unknown device',
      ccm: doubles(json['ccm']),
      residual: (json['residual'] as num).toDouble(),
      quality: CalibrationQuality.values.firstWhere(
        (q) => q.name == json['quality'],
        orElse: () => CalibrationQuality.poor,
      ),
      measured: (json['measured'] as List).map(doubles).toList(),
      perPatchError: doubles(json['perPatchError']),
    );
  }
}

/// 6-patch colour calibration: patch measurement, colour correction matrix,
/// and session storage (flutter_secure_storage).
class CalibrationService {
  static const String _currentKey = 'calibration_current';
  static const String _historyKey = 'calibration_history';
  static const String _remindedKey = 'calibration_reminded_id';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Live current session for banners and gating. Null when none saved.
  static final ValueNotifier<CalibrationSession?> session =
      ValueNotifier<CalibrationSession?>(null);

  /// True when a saved session exists and is under 8 hours old.
  static bool get isValidNow => session.value?.isValid ?? false;

  /// Loads the saved session so [session] is correct at startup.
  static Future<void> init() async {
    await current();
  }

  static Future<CalibrationSession?> current() async {
    try {
      final raw = await _storage.read(key: _currentKey);
      final s = raw == null
          ? null
          : CalibrationSession.fromJson(
              jsonDecode(raw) as Map<String, dynamic>);
      session.value = s;
      return s;
    } catch (e) {
      if (kDebugMode) debugPrint('CalibrationService.current failed: $e');
      return null;
    }
  }

  static Future<bool> isValid() async => (await current())?.isValid ?? false;

  /// Saved sessions, newest first.
  static Future<List<CalibrationSession>> history() async {
    try {
      final raw = await _storage.read(key: _historyKey);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => CalibrationSession.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      if (kDebugMode) debugPrint('CalibrationService.history failed: $e');
      return [];
    }
  }

  /// Saves [s] as the current session and adds it to the history.
  static Future<void> save(CalibrationSession s) async {
    final items = await history();
    items
      ..removeWhere((h) => h.id == s.id)
      ..insert(0, s);
    final trimmed = items.take(kCalibrationHistoryMax).toList();
    await _storage.write(key: _currentKey, value: jsonEncode(s.toJson()));
    await _storage.write(
      key: _historyKey,
      value: jsonEncode(trimmed.map((h) => h.toJson()).toList()),
    );
    session.value = s;
  }

  /// Builds an unsaved session from 6 measured patches.
  static Future<CalibrationSession> buildSession(
      List<PatchMeasurement> patches) async {
    final measured = patches.map((p) => List<double>.from(p.mean)).toList();
    final result = computeCcm(
      measured,
      kCalibrationPatches
          .map((p) => p.rgb.map((v) => v.toDouble()).toList())
          .toList(),
    );
    final now = DateTime.now();
    final sameDay = (await history())
        .where((h) =>
            h.createdAt.year == now.year &&
            h.createdAt.month == now.month &&
            h.createdAt.day == now.day)
        .length;
    String two(int v) => v.toString().padLeft(2, '0');
    return CalibrationSession(
      id: 'S-${now.year}-${two(now.month)}-${two(now.day)}-${two(sameDay + 1)}',
      createdAt: now,
      validUntil: now.add(kCalibrationValidity),
      deviceModel: await deviceModel(),
      ccm: result.ccm,
      residual: result.residual,
      quality: result.quality,
      measured: measured,
      perPatchError: result.perPatchError,
    );
  }

  /// Sends one "Recalibrate" notification per expired session.
  static Future<void> remindIfExpired() async {
    try {
      final s = await current();
      if (s == null || s.isValid) return;
      if (await _storage.read(key: _remindedKey) == s.id) return;
      await NotificationService.add(
        type: AppNotificationType.warning,
        title: 'Recalibrate',
        message: 'Your calibration is over 8 hours old.',
        action: AppNotificationAction.openCalibration,
      );
      await _storage.write(key: _remindedKey, value: s.id);
    } catch (e) {
      if (kDebugMode) debugPrint('CalibrationService.remind failed: $e');
    }
  }

  static Future<String> deviceModel() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        final maker = a.manufacturer.isEmpty
            ? ''
            : '${a.manufacturer[0].toUpperCase()}${a.manufacturer.substring(1)} ';
        return '$maker${a.model}'.trim();
      }
      if (Platform.isIOS) return (await info.iosInfo).modelName;
    } catch (e) {
      if (kDebugMode) debugPrint('CalibrationService.deviceModel failed: $e');
    }
    return 'Unknown device';
  }

  /// Measures a patch photo off the UI thread.
  static Future<PatchMeasurement> measurePatch(File file) async {
    final bytes = await file.readAsBytes();
    final result = await compute(_measureBytes, bytes);
    return PatchMeasurement(mean: result[0], std: result[1]);
  }

  /// Applies a row-major 3x3 [ccm] to an RGB value (0-255).
  static List<int> applyCcm(List<double> ccm, num r, num g, num b) {
    final v = [r / 255, g / 255, b / 255];
    return List<int>.generate(3, (j) {
      final out = v[0] * ccm[j] + v[1] * ccm[3 + j] + v[2] * ccm[6 + j];
      return (out * 255).round().clamp(0, 255);
    });
  }

  /// Least-squares 3x3 colour correction matrix M minimising ||C·M - R||,
  /// matching numpy.linalg.lstsq in training (no offset term).
  /// [measured] and [reference] are N x 3 lists in 0-255.
  static CcmResult computeCcm(
      List<List<double>> measured, List<List<double>> reference) {
    assert(measured.length == reference.length);
    final n = measured.length;
    final c = measured.map((p) => p.map((v) => v / 255).toList()).toList();
    final r = reference.map((p) => p.map((v) => v / 255).toList()).toList();

    // Normal equations: M = (CᵀC)⁻¹ CᵀR.
    final ctc = List.generate(3, (_) => List<double>.filled(3, 0));
    final ctr = List.generate(3, (_) => List<double>.filled(3, 0));
    for (var k = 0; k < n; k++) {
      for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 3; j++) {
          ctc[i][j] += c[k][i] * c[k][j];
          ctr[i][j] += c[k][i] * r[k][j];
        }
      }
    }
    final inv = _invert3(ctc);
    final m = List<double>.filled(9, 0);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        var sum = 0.0;
        for (var k = 0; k < 3; k++) {
          sum += inv[i][k] * ctr[k][j];
        }
        m[i * 3 + j] = sum;
      }
    }

    final errors = <double>[];
    var sumSq = 0.0;
    for (var k = 0; k < n; k++) {
      var sq = 0.0;
      for (var j = 0; j < 3; j++) {
        final out = c[k][0] * m[j] + c[k][1] * m[3 + j] + c[k][2] * m[6 + j];
        final d = out - r[k][j];
        sq += d * d;
      }
      errors.add(math.sqrt(sq));
      sumSq += sq;
    }
    return CcmResult(
      ccm: m,
      residual: math.sqrt(sumSq / n),
      perPatchError: errors,
    );
  }

  static List<List<double>> _invert3(List<List<double>> a) {
    final det = a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1]) -
        a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0]) +
        a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0]);
    if (det.abs() < 1e-12) {
      throw StateError('Calibration patches are not independent');
    }
    double cof(int r0, int r1, int c0, int c1) =>
        a[r0][c0] * a[r1][c1] - a[r0][c1] * a[r1][c0];
    return [
      [cof(1, 2, 1, 2) / det, -cof(0, 2, 1, 2) / det, cof(0, 1, 1, 2) / det],
      [-cof(1, 2, 0, 2) / det, cof(0, 2, 0, 2) / det, -cof(0, 1, 0, 2) / det],
      [cof(1, 2, 0, 1) / det, -cof(0, 2, 0, 1) / det, cof(0, 1, 0, 1) / det],
    ];
  }
}

/// Isolate entry: decodes, EXIF-orients, and measures the central 50%.
/// Returns [mean, std], each per channel in 0-255.
List<List<double>> _measureBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unreadable image');
  final oriented = img.bakeOrientation(decoded);
  final w = oriented.width, h = oriented.height;
  final crop = img.copyCrop(oriented,
      x: w ~/ 4, y: h ~/ 4, width: w ~/ 2, height: h ~/ 2);
  final rgb = crop
      .convert(format: img.Format.uint8, numChannels: 3)
      .getBytes(order: img.ChannelOrder.rgb);

  final sum = [0.0, 0.0, 0.0];
  final sumSq = [0.0, 0.0, 0.0];
  final count = rgb.length ~/ 3;
  for (var i = 0; i < rgb.length; i += 3) {
    for (var ch = 0; ch < 3; ch++) {
      final v = rgb[i + ch].toDouble();
      sum[ch] += v;
      sumSq[ch] += v * v;
    }
  }
  final mean = [for (final s in sum) s / count];
  final std = [
    for (var ch = 0; ch < 3; ch++)
      math.sqrt(math.max(0, sumSq[ch] / count - mean[ch] * mean[ch])),
  ];
  return [mean, std];
}
